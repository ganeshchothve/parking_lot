class UserRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :comments, type: String
  field :status, type: String, default: 'pending'

  belongs_to :project_unit, optional: true
  belongs_to :receipt, optional: true
  belongs_to :user, optional: true
  has_many :assets, as: :assetable

  validates :user_id, :project_unit_id, :comments, presence: true
  validates :status, inclusion: {in: Proc.new{ UserRequest.available_statuses.collect{|x| x[:id]} } }
  validates :project_unit_id, uniqueness: {scope: :user_id, message: 'already has a cancellation request.'}

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'resolved', text: 'Resolved'}
    ]
  end

  # TODO: on create send email to CRM team

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:status].present?
        selector[:status] = params[:fltrs][:status]
      end
      if params[:fltrs][:user_id].present?
        selector[:user_id] = params[:fltrs][:user_id]
      end
    end
    self.where(selector)
  end
end
