class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :status, type: String, default: 'available'

  belongs_to :user, optional: true
  has_many :receipts
  has_many :user_requests

  validates :status, :name, presence: true
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :user_id, presence: true, if: Proc.new { |unit| unit.status != 'available' }

  def self.available_statuses
    [
      {id: 'available', text: 'Available'},
      {id: 'hold', text: 'Hold'},
      {id: 'blocked', text: 'Blocked'},
      {id: 'booked_tentative', text: 'Tentative Booked'},
      {id: 'booked_confirmed', text: 'Confirmed Booked'}
    ]
  end
end
