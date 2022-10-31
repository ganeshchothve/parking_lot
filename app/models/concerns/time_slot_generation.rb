module TimeSlotGeneration
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    # Fields
    field :token_number, type: Integer
    field :token_prefix, type: String

    increments :token_number, auto: false, scope: proc { "p#{project_id}_t#{token_type_id}" }

    # Associations
    belongs_to :token_type, optional: true

    # Validations
    validates :token_number, uniqueness: {scope: [:project_id, :token_type_id]}, allow_nil: true
    validates :token_type_id, presence: true, if: proc { direct_payment? }

    # Callbacks
    before_save :assign_token_number, if: proc { direct_payment? }

    # Associations
    belongs_to :time_slot, optional: true
  end

  def assign_token_number
    # Checks to handle following case:
    #   receipt is in clearance_pending & token number is assigned.
    #   admin made it blank afterwards & saved it.
    #   receipt goes in success from clearance_pending, then in this case do not assign token again as it was intentionally kept blank by admin. He can assign new token again if he wants.
    #   :_token_number is an internal dynamic field kept for reference to know if the token number is being assigned for the first time or it was made blank after assigning on receipt.
    if token_number_changed? || (status_changed? && status.in?(%w(clearance_pending success)) && !(self[:_token_number].present? && token_number.blank?))
      # Case when token number is made blank after its assigned, do not assign token again in this case as it is intentionally kept blank by admin.
      if !(token_number_changed? && token_number_was.present? && token_number.blank?) && (token_number.blank? && is_eligible_for_token_number_assignment?)
        if token_type.incrementor_exists?
          begin
            assign!(:token_number)
          end while Receipt.where(token_number: token_number, project_id: project_id, token_type_id: token_type_id).any?

          self.token_prefix = token_type.token_prefix
          self.time_slot = fetch_time_slot if project.enable_slot_generation?
          # for reference, if the token has been made blank by the admin.
          generate_coupon
          self[:_token_number] = token_number
        else
          errors.add(:token_type, "#{token_type.name} is not activated")
          throw(:abort)
        end
      end

    end
  end

  def generate_coupon
    discount = Discount.where(project_id: self.project_id, token_type_id: self.token_type_id , start_token_number: { '$lte': token_number }, end_token_number: { '$gte': token_number }).first
    if discount
      attrs = discount.attributes.deep_dup
      attrs.except! :_id, :created_at, :updated_at, :payment_adjustments, :project_id, :token_type_id
      attrs.merge!(receipt: self, discount: discount)
      attrs[:value] = discount.payment_adjustments.nin(absolute_value: [nil, '']).collect{ |payment_adjustment| payment_adjustment.absolute_value }.try(:sum).try(:round, 2)
      attrs[:variable_discount] = discount.payment_adjustments.nin(formula: [nil, '']).collect{ |payment_adjustment| payment_adjustment.calculate(self) }.try(:sum).try(:round, 2)
      _coupon = Coupon.create(attrs)
    end
  end

  def is_eligible_for_token_number_assignment?
    direct_payment? && status.in?(%w(clearance_pending success))
  end

  def get_token_number
    token_number.present? ? self.token_prefix.to_s + token_number.to_s : '--'
  end

  def set_time_slot
    self.update(time_slot: fetch_time_slot) if token_number && time_slot_id.blank?
  end

  def fetch_time_slot
    project.time_slots.reject {|ts| ts.allotted.to_i >= ts.capacity.to_i}.to_a.sort_by {|ts| DateTime.parse(ts.start_time_to_s)}.first
  end
end
