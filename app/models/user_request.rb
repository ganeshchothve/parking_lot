class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :comments, type: String
  field :status, type: String, default: 'pending'

  belongs_to :project_unit, optional: true
  belongs_to :receipt, optional: true
  belongs_to :user, optional: true

  validates :user_id, :comments, presence: true
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'resolved', text: 'Resolved'}
    ]
  end

  # TODO: on create send email to CRM team
end
