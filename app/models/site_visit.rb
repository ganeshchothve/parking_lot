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
  extend DocumentsConcern

  REJECTION_REASONS = ["budget_not_match", "location_not_match", "possession_not_match", "didnt_visit", "different_cp"]
  DOCUMENT_TYPES = []

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
  field :code, type: String

  belongs_to :booking_portal_client, class_name: 'Client'
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
  has_many :assets, as: :assetable

  accepts_nested_attributes_for :notes, reject_if: :all_blank
  accepts_nested_attributes_for :assets, reject_if: :all_blank

  delegate :name, to: :project, prefix: true, allow_nil: true
  delegate :name, :role, :role?, :email, to: :manager, prefix: true, allow_nil: true

  scope :filter_by_id, ->(_id) { where(_id: _id) }
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
  scope :filter_by_channel_partner_id, ->(channel_partner_id) {where(channel_partner_id: channel_partner_id)}
  scope :filter_by_is_revisit, ->(is_revisit) { where(is_revisit: is_revisit.to_s == 'true') }
  scope :filter_by_booking_portal_client_id, ->(booking_portal_client_id) { where(booking_portal_client_id: booking_portal_client_id) }
  scope :filter_by_code, ->(code) { where(code: code) }

  scope :incentive_eligible, ->(category) do
    if category == 'walk_in'
      where(approval_status: {'$nin': %w(rejected)}, is_revisit: false)
    else
      none
    end
  end

  validates :scheduled_on, :status, :site_visit_type, :created_by, :code, presence: true
  validates :conducted_on, :conducted_by, presence: true, if: Proc.new { |sv| sv.status == 'conducted' }
  validate :existing_scheduled_sv, on: :create
  validate :validate_scheduled_on_datetime
  validates :time_slot, presence: true, if: Proc.new { |sv| sv.site_visit_type == 'token_slot' }
  validates :notes, copy_errors_from_child: true
  validates :assets, copy_errors_from_child: true

  def lead_manager
    LeadManager.where(booking_portal_client_id: booking_portal_client_id, manager_id: manager_id, site_visit_id: id).first
  end

  def tentative_incentive_eligible?(category=nil)
    if category.present?
      if category == 'walk_in'
        !is_revisit? && scheduled?
      end
    else
      _tentative_incentive_eligible?
    end
  end

  def draft_incentive_eligible?(category=nil)
    if category.present?
      if category == 'walk_in'
        !is_revisit? && verification_approved? && (conducted? || paid?)
      end
    else
      _draft_incentive_eligible?
    end
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    project_ids = (params[:current_project_id].present? ? [params[:current_project_id]] : user.project_ids)
    if params[:lead_id].blank? && !user.buyer?
      case user.role.to_s
      when 'channel_partner'
        custom_scope = { manager_id: user.id, channel_partner_id: user.channel_partner_id}
      when 'cp_owner'
        custom_scope = {channel_partner_id: user.channel_partner_id}
      when 'cp_admin'
        custom_scope = {}
      when 'cp'
        custom_scope = {}
      when 'dev_sourcing_manager', 'billing_team'
        custom_scope = {}
      when 'admin', 'sales'
        custom_scope = {}
      when 'superadmin'
        custom_scope = {}
      end
    end

    custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
    custom_scope = { user_id: user.id } if user.buyer?

    if !user.role.in?(User::ALL_PROJECT_ACCESS) || params[:current_project_id].present?
      custom_scope.merge!({project_id: { "$in": project_ids }})
    end

    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    custom_scope
  end

  def name
    "#{project.name}"
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

  def save_assets(params)
    site_visit = self
    errors = []
    site_visit.assign_attributes(params || {})
    unless site_visit.save
      errors = site_visit.errors.full_messages.uniq
    end
    site_visit.reload
    errors
  end

  private

  def validate_scheduled_on_datetime
    self.errors.add :base, 'Scheduled On should not be past date more than 4 days' if (self.scheduled_on_changed? && self.scheduled_on <  (Time.current.beginning_of_day - 4.days))
  end

  def existing_scheduled_sv
    self.errors.add :base, 'One Scheduled Site Visit Already Exists' if SiteVisit.where(booking_portal_client_id: self.booking_portal_client_id, lead_id: lead_id, status: 'scheduled', manager_id: self.manager_id).present?
  end
end
