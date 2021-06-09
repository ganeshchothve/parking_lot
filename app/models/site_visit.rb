class SiteVisit
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  include ArrayBlankRejectable
  include CrmIntegration
  include InsertionStringMethods
  extend FilterByCriteria

  belongs_to :project
  belongs_to :lead
  belongs_to :user
  belongs_to :creator, class_name: 'User'
  
  field :scheduled_on, type: DateTime
  field :status, type: String, default: 'scheduled'
  field :conducted_on, type: DateTime
  field :site_visit_type, type: String, default: 'visit'

  scope :filter_by_status, ->(_status) { where(status: { '$in' => _status }) }
  scope :filter_by_site_visit_type, ->(_status) { where(status: { '$in' => _site_visit_type }) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}
  scope :filter_by_user_id, ->(_user_id) { where(user_id: _user_id) }
  scope :filter_by_scheduled_on, ->(date) { start_date, end_date = date.split(' - '); where(scheduled_on: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_conducted_on, ->(date) { start_date, end_date = date.split(' - '); where(conducted_on: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }

  validates :scheduled_on, :status, :site_visit_type, presence: true
  validates :conducted_on, presence: true, if: Proc.new { |sv| sv.status == 'conducted' }
  validate :existing_scheduled_sv, on: :create

  def self.statuses
    [
      { id: 'scheduled', text: 'Scheduled' },
      { id: 'conducted', text: 'Conducted' },
      { id: 'pending', text: 'Pending' },
      { id: 'missed', text: 'Missed' }
    ]
  end

  def self.available_sort_options
    [
      { id: 'created_at.asc', text: 'Created - Oldest First' },
      { id: 'created_at.desc', text: 'Created - Newest First' },
      { id: 'scheduled_on.asc', text: 'Scheduled On - Oldest First' },
      { id: 'scheduled_on.desc', text: 'Scheduled On- Newest First' },
      { id: 'conducted_on.asc', text: 'Conducted On - Oldest First' },
      { id: 'conducted_on.desc', text: 'Conducted On - Newest First' }
    ]
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    if params[:lead_id].blank? && !user.buyer?
      if user.role?('channel_partner')
        custom_scope = { manager_id: user.id }
      #elsif user.role?('cp_admin')
      #  custom_scope = { lead_id: { "$in": Lead.nin(manager_id: [nil, '']).distinct(:id) } }
      #elsif user.role?('cp')
      #  channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
      #  custom_scope = { lead_id: { "$in": Lead.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
      end
    end

    custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
    custom_scope = { user_id: user.id } if user.buyer?

    custom_scope[:booking_detail_id] = params[:booking_detail_id] if params[:booking_detail_id].present?
    custom_scope
  end

  def sync(erp_model, sync_log)
    # TODO: Handle
  end

  def name
    "#{project.name} - #{status}"
  end

  alias :resource_name :name

  private
  def existing_scheduled_sv
    self.errors.add :base, 'One Scheduled Site Visit Already Exists' if SiteVisit.where(lead_id: lead_id, status: 'scheduled').present?
  end
end
