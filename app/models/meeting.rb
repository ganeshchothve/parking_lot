class Meeting
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include CrmIntegration
  include MeetingStateMachine
  include ApplicationHelper
  extend ApplicationHelper
  extend FilterByCriteria
  extend DocumentsConcern

  DOCUMENT_TYPES = ['photo', 'collateral']

  field :topic, type: String
  field :meeting_type, type: String
  field :provider, type: String
  field :provider_url, type: String
  field :scheduled_on, type: DateTime
  field :status, type: String, default: 'draft'
  field :duration, type: Integer, default: 60
  field :agenda, type: String
  field :roles, type: Array, default: []
  field :broadcast, type: Boolean, default: false

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :project, optional: true
  belongs_to :campaign, optional: true
  belongs_to :creator, class_name: 'User'
  has_many :assets, as: :assetable
  has_and_belongs_to_many :participants, class_name: 'User'

  attr_accessor :toggle_participant_id

  validates :topic, :meeting_type, :scheduled_on, :status, :duration, :agenda, presence: true
  validates :provider, :provider_url, presence: true, if: Proc.new { |sv| sv.meeting_type == 'webinar' }
  validates :duration, numericality: {greater_than: 0}
  validates :roles, array: { inclusion: {allow_blank: false, in: proc { |meeting| User.available_roles(meeting.creator.booking_portal_client) } } }, if: Proc.new {|meeting| meeting.creator_id.present? }
  #validate :scheduled_on_future_on_create, on: :create

  def participant?(user_id)
    participant_ids.include?(user_id.is_a?(User) ? user_id.id : user_id)
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    project_ids = (params[:current_project_id].present? ? [params[:current_project_id]] : user.project_ids)
    custom_scope[:roles] = {'$in': [user.role] }  unless user.role == 'superadmin' || user.role == 'admin'
    custom_scope[:project_id] = params[:project_id] if params[:project_id].present?
    custom_scope[:campaign_id] = params[:campaign_id] if params[:campaign_id].present?
    custom_scope[:status] = {'$in': ['scheduled', 'completed'] } if %w[crm sales_admin sales channel_partner gre billing_team user employee_user management_user].include?(user.role)
    if !user.role.in?(User::ALL_PROJECT_ACCESS) || params[:current_project_id].present?
      custom_scope[:project_id] = { project_id: { "$in": project_ids } }
    end
    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    custom_scope
  end

  private
  def scheduled_on_future_on_create
    self.errors.add :scheduled_on, ' has to be in future.' if scheduled_on.present? && scheduled_on < Date.today
  end
end
