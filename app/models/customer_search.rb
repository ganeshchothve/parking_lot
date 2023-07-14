class CustomerSearch
  include Mongoid::Document
  include Mongoid::Timestamps

  ALLOWED_STEPS = %w[search customer kyc sitevisit queued not_queued]

  field :step, type: String, default: 'search'

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :customer, class_name: 'Lead', optional: true
  belongs_to :user_kyc, optional: true
  belongs_to :site_visit, optional: true

  validates_presence_of :customer_id, on: :customer, message: 'not found'
  validate :customer_validity, on: :kyc
  validate :customer_kyc_validity, on: :sitevisit

  def customer_validity
    if customer && !customer.valid?
      self.errors.add(:base, customer.errors.full_messages)
    end
  end

  def customer_kyc_validity
    if user_kyc && !user_kyc.valid?
      self.errors.add(:base, user_kyc.errors.full_messages)
    end
  end

  def crossed_step(st)
    current_index = ALLOWED_STEPS.index(self.step)
    index = ALLOWED_STEPS.index(st)
    current_index > index
  end
end
