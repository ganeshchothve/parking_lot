class Discount
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :start_token_number, type: Integer
  field :end_token_number, type: Integer

  has_many :coupons
  belongs_to :project
  belongs_to :token_type
  embeds_many :payment_adjustments, as: :payable

  accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  validates :name, :start_token_number, :end_token_number, presence: true
  validate :not_overlapping
  validate :valid_token_numbers
  validate -> do
    payment_adjustments_not_marked_for_destruction = payment_adjustments.reject(&:marked_for_destruction?)
    errors.add(:payment_adjustments, :too_short, count: 1) if payment_adjustments_not_marked_for_destruction.length < 1
  end

  before_destroy :discount_with_coupons?

  def valid_token_numbers
    errors.add(:base, 'End token number should be greater than start token number') if end_token_number <= start_token_number
  end

  def not_overlapping
    errors.add(:base, "Token range is overlapping with other discounts") unless Discount.where(booking_portal_client_id: self.booking_portal_client_id, project_id: self.project_id, token_type_id: self.token_type_id).nin(id: [self.id]).blank? ||
      Discount.where(booking_portal_client_id: self.booking_portal_client_id, project_id: self.project_id, token_type_id: self.token_type_id).nin(id: [self.id]).pluck(:start_token_number, :end_token_number)
      .map { |x| (x.first..x.last).to_a }
      .map { |x| (x & (start_token_number..end_token_number).to_a).blank? }
      .inject(:&)
  end

  def editable_payment_adjustments
    self.payment_adjustments.in(editable: [true, nil])
  end

  def non_editable_payment_adjustments
    self.payment_adjustments.where(editable: false)
  end

  def discount_with_coupons?
    if self.coupons.present?
      errors.add(:base, "Cannot delete discount with coupons generated")
      throw(:abort)
    else
      return true
    end
  end

  def self.available_fields
    ["agreement_price"]
  end
end
