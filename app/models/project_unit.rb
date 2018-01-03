class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  def self.blocking_amount
    30000
  end

  field :name, type: String
  field :base_price, type: Float
  field :booking_price, type: Float
  field :status, type: String, default: 'available'

  belongs_to :user, optional: true
  has_many :receipts
  has_many :user_requests
  has_and_belongs_to_many :user_kycs

  validates :status, :name, :base_price, :booking_price, presence: true
  validates :base_price, numericality: { greater_than: 0 }
  validates :booking_price, numericality: { greater_than: ProjectUnit.blocking_amount }
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :user_id, :user_kyc_ids, presence: true, if: Proc.new { |unit| ['available', 'not_available'].exclude?(unit.status) }

  def self.available_statuses
    [
      {id: 'available', text: 'Available'},
      {id: 'not_available', text: 'Not Available'},
      {id: 'error', text: 'Error'},
      {id: 'hold', text: 'Hold'},
      {id: 'blocked', text: 'Blocked'},
      {id: 'booked_tentative', text: 'Tentative Booked'},
      {id: 'booked_confirmed', text: 'Confirmed Booked'}
    ]
  end

  # TODO: reset the userid always if status changes and is available or not_available

  def pending_balance
    if self.user_id.present?
      receipts_total = Receipt.where(user_id: self.user_id, project_unit_id: self.id, status: "success").sum(:total_amount)
      return (self.booking_price - receipts_total)
    else
      return nil
    end
  end

  def self.sync_trigger_attributes
    ['status', 'user_id']
  end

  def sync_with_third_party_inventory
    # TODO: write the actual code here
    third_party_inventory_response_status = 200
    return (third_party_inventory_response_status == 200)
  end

  def sync_with_selldo
    # TODO: write the actual code here
    selldo_response_status = 200
    return (selldo_response_status == 200)
  end

  def process_payment!(receipt)
    if receipt.status == 'success'
      if receipt.payment_type == 'blocking' && self.status == 'hold'
        self.status = 'blocked'
      elsif receipt.payment_type == 'booking' && (self.status == 'booked_tentative' || self.status == 'blocked')
        if self.pending_balance == 0
          self.status = 'booked_confirmed'
        else
          self.status = 'booked_tentative'
        end
      end
    elsif receipt.status == 'failed'
      if receipt.payment_type == 'blocking' && self.status == 'hold'
        self.status = 'available'
        self.user_id = nil
      end
    end
    self.save(validate: false)
  end
end
