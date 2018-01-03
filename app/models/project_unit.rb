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

  validates :status, :name, :base_price, :booking_price, presence: true
  validates :base_price, numericality: { greater_than: 0 }
  validates :booking_price, numericality: { greater_than: ProjectUnit.blocking_amount }
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :user_id, presence: true, if: Proc.new { |unit| ['available', 'not_available'].exclude?(unit.status) }

  def self.available_statuses
    [
      {id: 'available', text: 'Available'},
      {id: 'not_available', text: 'Not Available'},
      {id: 'hold', text: 'Hold'},
      {id: 'blocked', text: 'Blocked'},
      {id: 'booked_tentative', text: 'Tentative Booked'},
      {id: 'booked_confirmed', text: 'Confirmed Booked'}
    ]
  end

  # reset the userid always if status changes and is available or not_available

  # Takes the sfdc response json / xml & applies it to the model attributes
  def map_sfdc(sfdc_response)
    self.attributes = sfdc_response[:project_unit] #TODO: modify this based on sfdc's reposnse json / xml
  end

  def total_balance_pending
    if self.user_id.present?
      receipts_total = Receipt.where(user_id: self.user_id, project_unit_id: self.id, status: "success").sum(:total_amount)
      return (self.booking_price - receipts_total)
    else
      return nil
    end
  end
end
