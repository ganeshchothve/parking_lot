class LeadManager
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria
  extend DocumentsConcern

  COUNT_STATUS = %w(fresh_lead active_in_same_cp no_count accompanied_credit accompanied_count_to_cp count_given)
  LEAD_STATUS = %w(already_exists registered)
  DOCUMENT_TYPES = %w[sitevisit_form]
  SITEVISIT_STATUS = %w[scheduled conducted]

  #field :registered_at, type: Date
  #field :count_status, type: String
  #field :lead_status, type: String
  #field :sitevisit_status, type: String
  #field :sitevisit_date, type: String

  field :first_name, type: String
  field :last_name, type: String
  field :phone, type: String
  field :email, type: String
  field :expiry_date, type: Date

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :lead, optional: true
  belongs_to :project
  belongs_to :site_visit, optional: true
  belongs_to :user
  belongs_to :channel_partner
  #belongs_to :cp_manager, class_name: 'User', optional: true
  #belongs_to :cp_admin, class_name: 'User', optional: true
  has_many :assets, as: :assetable

  default_scope -> { desc(:created_at) }
  #scope :filter_by_count_status, ->(status) { where(count_status: status) }
  #scope :filter_by_lead_status, ->(status) { where(lead_status: status) }
  scope :filter_by_lead_id, ->(lead_id) { where(lead_id: lead_id) }
  scope :filter_by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_expiry_date, ->(date) { start_date, end_date = date.split(' - '); where(expiry_date: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  #scope :filter_by_registered_at, ->(date) { start_date, end_date = date.split(' - '); where(registered_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }

  validates :first_name, presence: true
  validates :first_name, :last_name, name: true, allow_blank: true
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile mobile fixed_line premium_rate] }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP } , allow_blank: true

  def manager_name
    str = self.user&._name
    str += " (#{channel_partner.company_name})" if channel_partner.present? && channel_partner.company_name.present?
    str
  end

  def lead_validity_period
    (self.expiry_date > Date.current) ? "#{(self.expiry_date - Date.current).to_i} Days" : '0 Days'
  end

  def can_extend_validity?
    self.lead.active_lead_managers.blank? #&& self.count_status != 'no_count'
  end

  def push_source_to_selldo
    if lead.push_to_crm?
      _selldo_api_key = self.lead.project.selldo_api_key
      if _selldo_api_key.present?
        campaign_resp = { source: 'Channel Partner', sub_source: self.user.name, project_id: self.project.selldo_id.to_s }
        SelldoLeadUpdater.perform_async(self.lead_id.to_s, { action: 'add_campaign_response', api_key: _selldo_api_key }.merge(campaign_resp).with_indifferent_access)
        SelldoNotePushWorker.perform_async(self.lead.lead_id, self.user.id.to_s, "Validity: #{self.lead_validity_period}, Expiry: #{self.expiry_date.try(:strftime, '%d/%m/%Y') || '-'}")
      end
    end
  end

  def self.user_based_scope(user, _params = {})
    custom_scope = {}
    case user.role
    when 'channel_partner'
      custom_scope = { user_id: user.id, channel_partner_id: user.channel_partner_id }
    when 'cp_owner'
      custom_scope = { channel_partner_id: user.channel_partner_id }
    when 'cp'
      custom_scope = { user_id: { '$in': User.where(role: 'channel_partner', manager_id: user.id).distinct(:id) } }
    when 'cp_admin'
      cp_ids = User.all.cp.where(manager_id: user.id).distinct(:id)
      custom_scope = { user_id: { '$in': User.where(role: 'channel_partner', manager_id: {'$in': cp_ids}).distinct(:id) } }
    end
    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client_id})
    custom_scope
  end

end
