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
    #before_update :finalise_time_slot

    # Associations
    embeds_one :time_slot
    accepts_nested_attributes_for :time_slot, reject_if: :all_blank
  end

  def assign_token_number
    if token_type.incrementor_exists?
      # Checks to handle following case:
      #   receipt is in clearance_pending & token number is assigned.
      #   admin made it blank afterwards & saved it.
      #   receipt goes in success from clearance_pending, then in this case do not assign token again as it was intentionally kept blank by admin. He can assign new token again if he wants.
      #   :_token_number is an internal dynamic field kept for reference to know if the token number is being assigned for the first time or it was made blank after assigning on receipt.
      if token_number_changed? || (status_changed? && status.in?(%w(clearance_pending success)) && !(self[:_token_number].present? && token_number.blank?))
        # Case when token number is made blank after its assigned, do not assign token again in this case as it is intentionally kept blank by admin.
        if !(token_number_changed? && token_number_was.present? && token_number.blank?) && (token_number.blank? && is_eligible_for_token_number_assignment?)
          begin
            assign!(:token_number)
          end while Receipt.where(token_number: token_number, project_id: project_id, token_type_id: token_type_id).any?

          self.token_prefix = token_type.token_prefix
          #self.time_slot = calculate_time_slot if current_client.enable_slot_generation?
          # for reference, if the token has been made blank by the admin.
          self[:_token_number] = token_number
        end
      end
    else
      errors.add(:token_type, "#{token_type.name} is not activated")
      throw(:abort)
    end
  end

  def is_eligible_for_token_number_assignment?
    direct_payment? && status.in?(%w(clearance_pending success))
  end

  def get_token_number
    token_number.present? ? self.token_prefix.to_s + token_number.to_s : '--'
  end

  def set_time_slot
    self.set(time_slot: calculate_time_slot) if token_number
  end

  def calculate_time_slot
    slots_per_day = ((current_client.end_time - current_client.start_time) / 60).to_i / current_client.duration
    slot_number = (token_number - 1) / current_client.capacity
    date = current_client.slot_start_date + (slot_number / slots_per_day).days
    slot_start_time = current_client.start_time + ((slot_number % slots_per_day) * current_client.duration).minutes
    date = Time.zone.parse(date.strftime('%Y-%m-%d') + ' ' + slot_start_time.to_s(:time))
    slot = TimeSlot.new(date: date, start_time: date, end_time: date + current_client.duration.minutes)
  end

  def update_time_slot
    slot = calculate_time_slot
    if slot.start_time < Time.zone.now # if time slot date is in the past
      errors.add(:token_number, 'Time Slot for this token number is in the past.')
      throw(:abort)
    else
      self.time_slot = slot
    end
  end

  def finalise_time_slot
    self.time_slot = nil if token_number_changed? && token_number.blank?

    if is_eligible_for_token_number_assignment?
      if current_client.enable_slot_generation?
        if token_number_changed?
          update_time_slot if token_number.present? && !(status_changed? && status_was == 'pending' && status == 'clearance_pending') # Don't run for the first time when token is assigned by the system.
        else
          self.time_slot = calculate_time_slot if time_slot.blank? && token_number.present?
        end
      end
    elsif token_number_changed? && token_number.present?
      errors.add(:base, "Receipt not eligible for applying token number")
      throw(:abort)
    end
  end
end
