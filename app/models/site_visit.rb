require 'autoinc'
class SiteVisit
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include SiteVisitStateMachine
  include ArrayBlankRejectable
  include CrmIntegration
  include InsertionStringMethods
  extend FilterByCriteria
  include Mongoid::Autoinc
  include QueueNumberAssignment
  include IncentiveSchemeAutoApplication

  REJECTION_REASONS = ["budget_not_match", "location_not_match", "possession_not_match", "didnt_visit", "different_cp"]

  belongs_to :project
  belongs_to :lead
  belongs_to :user
  belongs_to :creator, class_name: 'User'
  belongs_to :time_slot, optional: true
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :cp_manager, class_name: 'User', optional: true
  belongs_to :cp_admin, class_name: 'User', optional: true
  has_many :notes, as: :notable
  has_many :invoices, as: :invoiceable

  accepts_nested_attributes_for :notes, reject_if: :all_blank

  field :scheduled_on, type: DateTime
  field :conducted_on, type: DateTime
  field :site_visit_type, type: String, default: 'visit'
  field :selldo_id, type: String
  field :is_revisit, type: Boolean
  field :cp_code, type: String
  field :sales_id, type: BSON::ObjectId
  field :created_by, type: String
  field :conducted_by, type: String
  field :rejection_reason, type: String

  delegate :name, to: :project, prefix: true, allow_nil: true

  scope :filter_by_status, ->(_status) { where(status: (_status.is_a?(String) ? _status : { '$in' => _status })) }
  scope :filter_by_approval_status, ->(_approval_status) { where(approval_status: (_approval_status.is_a?(String) ? _approval_status : { '$in' => _approval_status })) }
  scope :filter_by_site_visit_type, ->(_site_visit_type) { where(status: (_site_visit_type.is_a?(String) ? _site_visit_type : { '$in' => _site_visit_type })) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}
  scope :filter_by_user_id, ->(_user_id) { where(user_id: _user_id) }
  scope :filter_by_scheduled_on, ->(date) { start_date, end_date = date.split(' - '); where(scheduled_on: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_conducted_on, ->(date) { start_date, end_date = date.split(' - '); where(conducted_on: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_manager_id, ->(manager_id) {where(manager_id: manager_id) }
  scope :filter_by_cp_manager_id, ->(cp_manager_id) {where(cp_manager_id: cp_manager_id) }
  scope :incentive_eligible, ->(category) do
    if category == 'walk_in'
      where(approval_status: 'approved', status: {'$in': %w(conducted paid)})
    else
      all.not_eligible
    end
  end

  validates :scheduled_on, :status, :site_visit_type, :created_by, presence: true
  validates :conducted_on, :conducted_by, presence: true, if: Proc.new { |sv| sv.status == 'conducted' }
  validate :existing_scheduled_sv, on: :create
  validate :validate_scheduled_on_datetime
  validates :time_slot, presence: true, if: Proc.new { |sv| sv.site_visit_type == 'token_slot' }
  validates :notes, copy_errors_from_child: true

  def incentive_eligible?(category=nil)
    if category.present?
      if category == 'walk_in'
        verification_approved? && (conducted? || paid?)
      end
    else
      _incentive_eligible?
    end
  end

  def self.statuses
    [
      { id: 'scheduled', text: 'Scheduled' },
      { id: 'conducted', text: 'Conducted' },
      { id: 'pending', text: 'Pending' },
      { id: 'missed', text: 'Missed' }
    ]
  end

  def self.approval_statuses
    [
      { id: 'pending', text: 'Pending' },
      { id: 'approved', text: 'Approved' },
      { id: 'rejected', text: 'Rejected' }
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
        custom_scope = { manager_id: user.id, channel_partner_id: user.channel_partner_id }
      elsif user.role?('cp_owner')
        custom_scope = {channel_partner_id: user.channel_partner_id}
      elsif user.role?('cp_admin')
        custom_scope = {cp_admin_id: user.id}
      elsif user.role?('cp')
        custom_scope = {cp_manager_id: user.id}
      elsif user.role?('dev_sourcing_manager')
        custom_scope = { project_id: user.selected_project_id }
      end
    end

    custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
    custom_scope = { user_id: user.id } if user.buyer?

    custom_scope
  end

  def name
    "#{project.name} - #{status}"
  end

  alias :resource_name :name
  # Used in incentive invoice
  alias :invoiceable_manager :manager
  alias :invoiceable_date :scheduled_on

  def name_in_invoice
    self.lead.name.to_s
  end

  def update_data_from_selldo(data)
    self.status = data.dig('site_visit', 'status')
    if data.dig('site_visit', 'status') == 'conducted' && data.dig('site_visit', 'conducted_on').present?
      self.conducted_on = (DateTime.parse(data.dig('site_visit', 'conducted_on')) rescue nil)
    end
    self.save
  end

  def slot_status
    case status.to_s
    when 'scheduled', 'pending'
      'assigned'
    when 'missed'
      'missed'
    when 'conducted'
      'visited'
    end
  end

  private

  def validate_scheduled_on_datetime
    self.errors.add :base, 'Scheduled On should not be past date' if self.scheduled_on.beginning_of_day < Time.now.beginning_of_day
  end

  def existing_scheduled_sv
    self.errors.add :base, 'One Scheduled Site Visit Already Exists' if SiteVisit.where(lead_id: lead_id, status: 'scheduled').present?
  end
end
