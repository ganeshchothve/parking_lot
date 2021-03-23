class CpLeadActivity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  COUNT_STATUS = %w(fresh_lead active_in_same_cp no_count accompanied_credit accompanied_count_to_cp count_given)
  LEAD_STATUS = %w(already_exists registered)
  DOCUMENT_TYPES = %w[sitevisit_form]
  SITEVISIT_STATUS = %w[scheduled conducted]

  field :registered_at, type: Date
  field :count_status, type: String
  field :lead_status, type: String
  field :expiry_date, type: Date
  field :sitevisit_status, type: String
  field :sitevisit_date, type: String

  belongs_to :user
  belongs_to :lead
  has_many :assets, as: :assetable

  default_scope -> { desc(:created_at) }
  scope :filter_by_count_status, ->(status) { where(count_status: status) }
  scope :filter_by_lead_status, ->(status) { where(lead_status: status) }
  scope :filter_by_lead_id, ->(lead_id) { where(lead_id: lead_id) }
  scope :filter_by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :filter_by_project_id, ->(project_id) { lead_ids = Lead.where(project_id: project_id).distinct(:id); where(lead_id: { '$in': lead_ids }) }
  scope :filter_by_expiry_date, ->(date) { start_date, end_date = date.split(' - '); where(expiry_date: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_registered_at, ->(date) { start_date, end_date = date.split(' - '); where(registered_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }

  def self.user_based_scope(user, _params = {})
    custom_scope = {}
    custom_scope = { user_id: user.id } if user.role?('channel_partner')
    custom_scope = { user_id: { '$in': User.where(role: 'channel_partner', manager_id: user.id).distinct(:id) } } if user.role?(:cp_admin)
    custom_scope
  end

  def lead_validity_period
    (self.expiry_date > Date.current) ? "#{(self.expiry_date - Date.current).to_i} Days" : '0 Days'
  end

  def can_extend_validity?
    self.lead.active_cp_lead_activities.blank? && self.count_status != 'no_count'
  end

  def push_source_to_selldo
    _selldo_api_key = self.lead.user.booking_portal_client.selldo_api_key
    if self.user_id.present? && _selldo_api_key.present?
      campaign_resp = { source: 'Channel Partner', sub_source: self.user.name, project_id: self.lead.project.selldo_id.to_s }
      SelldoLeadUpdater.perform_async(self.lead.user_id.to_s, { action: 'add_campaign_response', api_key: _selldo_api_key }.merge(campaign_resp).with_indifferent_access)
    end
  end

  private

  def authorize_resource
    if %w[index export portal_stage_chart channel_partner_performance].include?(params[:action])
      authorize [current_user_role_group, User]
    elsif params[:action] == 'new' || params[:action] == 'create'
      if params[:role].present?
        authorize [current_user_role_group, User.new(role: params[:role], booking_portal_client_id: current_client.id)]
      else
        authorize [current_user_role_group, User.new(booking_portal_client_id: current_client.id)]
      end
    else
      authorize [current_user_role_group, @user]
    end
  end

  def apply_policy_scope
    custom_scope = CpLeadActivity.where(CpLeadActivity.user_based_scope(current_user, params))
    CpLeadActivity.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
