require 'autoinc'
class Lead
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include CrmIntegration
  include LeadNotifications
  include InsertionStringMethods
  extend FilterByCriteria
  extend ApplicationHelper
  include LeadStateMachine
  include DetailsMaskable
  include IncentiveSchemeAutoApplication
  extend DocumentsConcern

  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  DOCUMENT_TYPES = []

  attr_accessor :payment_link, :kylas_contact_id, :kylas_product_id, :sync_to_kylas, :manager_ids, :phone_update, :email_update

  field :first_name, type: String, default: ''
  field :last_name, type: String, default: ''
  field :email, type: String, default: ''
  field :phone, type: String, default: ''
  field :stage, type: String
  field :sitevisit_date, type: Date
  field :revisit_count, type: Integer
  field :last_revisit_date, type: Date
  field :registered_at, type: Date
  field :manager_change_reason, type: String
  field :referenced_manager_ids, type: Array, default: []

  field :source, type: String
  field :sub_source, type: String
  field :rera_id, type: String
  #
  # Casa specific fields
  field :lead_stage, type: String
  field :lead_status, type: String
  field :lead_lost_date, type: String
  field :sitevisit_status, type: String # synced from sell.do
  field :selldo_lead_registration_date, type: String
  # Casa fields end
  #
  field :iris_confirmation, type: Boolean, default: false
  field :lead_id, type: String #TO DO - Change name to selldo_id and use it throughout the system in place of lead_id on user.
  field :remarks, type: Array, default: [] # used to store the last five notes
  # used for dump latest queue_number or revisit queue number from sitevisit
  field :queue_number, type: Integer
  field :kyc_done, type: Boolean, default: false
  field :push_to_crm, type: Boolean, default: false

  # lead reassignment specific field
  field :accepted_by_sales, type: Boolean

  # Kylas Marketplace specific Fields
  field :kylas_lead_id, type: String
  field :kylas_deal_id, type: String
  field :kylas_pipeline_id, type: Integer

  embeds_many :state_transitions
  embeds_many :portal_stages

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :user
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :cp_manager, class_name: 'User', optional: true
  belongs_to :cp_admin, class_name: 'User', optional: true
  belongs_to :closing_manager, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :project
  has_many :receipts
  has_many :searches
  has_many :site_visits
  # this field used for track current sitevisit
  belongs_to :current_site_visit, class_name: 'SiteVisit', optional: true
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :assets, as: :assetable
  has_many :notes, as: :notable
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :emails, as: :triggered_by, class_name: 'Email'
  has_many :whatsapps, as: :triggered_by, class_name: 'Whatsapp'
  has_many :project_units
  has_many :cp_lead_activities
  has_many :invoices, as: :invoiceable
  #has_and_belongs_to_many :received_emails, class_name: 'Email', inverse_of: :recipients
  #has_and_belongs_to_many :cced_emails, class_name: 'Email', inverse_of: :cc_recipients
  #has_many :received_smses, class_name: 'Sms', inverse_of: :recipient
  #has_many :received_whatsapps, class_name: 'Whatsapp', inverse_of: :recipient

  accepts_nested_attributes_for :portal_stages, :site_visits, reject_if: :all_blank

  # validates_uniqueness_of :user, scope: :project_id, message: 'already exists for this project'
  validates :first_name, presence: true
  validates :first_name, :last_name, name: true, allow_blank: true
  # validate :phone_or_email_required, if: proc { |user| user.phone.blank? && user.email.blank? }
  # validates :phone, :email, uniqueness: { allow_blank: true }
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile mobile fixed_line premium_rate] }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP } , allow_blank: true
  validates :site_visits, copy_errors_from_child: true, if: :site_visits?
  validate :check_for_lead_conflict

  # delegate :first_name, :last_name, :name, :email, :phone, to: :user, prefix: false, allow_nil: true
  delegate :name, to: :project, prefix: true, allow_nil: true
  delegate :role, :role?, :email, to: :manager, prefix: true, allow_nil: true
  delegate :role, :role?, to: :user, prefix: true, allow_nil: true

  scope :filter_by__id, ->(_id) { where(_id: _id) }
  scope :filter_by_lead_id, ->(lead_id) { where(lead_id: lead_id) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :filter_by_manager_id, ->(manager_id) {where(manager_id: manager_id) }
  scope :filter_by_cp_manager_id, ->(cp_manager_id) {where(cp_manager_id: cp_manager_id) }
  scope :filter_by_channel_partner_id, ->(channel_partner_id) {where(channel_partner_id: channel_partner_id)}
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where({ '$and' => ["$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] ] }) }
  scope :filter_by_lead_stage, ->(lead_stage) { where(lead_stage: lead_stage) }
  scope :filter_by_customer_status, ->(*customer_status){ where(customer_status: { '$in': customer_status }) }
  scope :filter_by_queue_number, ->(queue_number){ where(queue_number: queue_number) }
  scope :filter_by_booking_portal_client_id, ->(booking_portal_client_id) { where(booking_portal_client_id: booking_portal_client_id) }
  scope :incentive_eligible, ->(category) do
    if category == 'lead'
      nin(manager_id: ['', nil])
    else
      none
    end
  end

  scope :filter_by_receipts, ->(receipts) do
    lead_ids = Receipt.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).distinct(:lead_id)
    if lead_ids.present?
      if receipts == 'yes'
        where(id: { '$in': lead_ids })
      elsif receipts == 'no'
        where(id: { '$nin': lead_ids })
      end
    end
  end

  scope :filter_by_booking_price, ->(paid) do
    lead_ids = BookingDetail.where(status: 'booked_confirmed').distinct(:lead_id)
    if lead_ids.present?
      if paid == 'yes'
        where(id: { '$in': lead_ids })
      elsif paid == 'no'
        where(id: { '$nin': lead_ids })
      end
    end
  end

  scope :filter_by_blocking_amount, ->(paid) do
    lead_ids = BookingDetail.where(status: { '$in': BookingDetail::BOOKING_STAGES}).distinct(:lead_id)
    if lead_ids.present?
      if paid == 'yes'
        where(id: { '$in': lead_ids })
      elsif paid == 'no'
        where(id: { '$nin': lead_ids })
      end
    end
  end

  scope :filter_by_registration_done, ->(paid) do
    lead_ids = BookingDetail.where(status: { '$in': BookingDetail::BOOKING_STAGES}).filter_by_tasks_completed('registration_done').distinct(:lead_id)
    if lead_ids.present?
      if paid == 'yes'
        where(id: { '$in': lead_ids })
      elsif paid == 'no'
        where(id: { '$nin': lead_ids })
      end
    end
  end

  scope :filter_by_kyc_done, ->(flag) do
    if flag == 'yes'
      where(kyc_done: true)
    elsif flag == 'no'
      where(kyc_done: false)
    end
  end

  scope :filter_by_token_number, ->(token_number) do
    lead_ids = Receipt.where(token_number: token_number).distinct(:lead_id)
    if lead_ids.present?
      where(id: { '$in': lead_ids })
    end
  end

  def tentative_incentive_eligible?(category=nil)
    if category.present?
      if category == 'lead'
        manager_id.present?
      else
        false
      end
    else
      _tentative_incentive_eligible?
    end
  end

  def draft_incentive_eligible?(category=nil)
    if category.present?
      if category == 'lead'
        manager_id.present?
      else
        false
      end
    else
      _draft_incentive_eligible?
    end
  end

  def manager_name
    self.cp_lead_activities.where(user_id: self.manager_id).first&.manager_name
  end

  def phone_or_email_required
    errors.add(:base, 'Email or Phone is required')
  end

  def first_booking_detail
    self.booking_details.in(status: BookingDetail::BOOKING_STAGES).order(created_at: :asc).first
  end

  def portal_stage
    portal_stages.desc(:updated_at).first
  end

  def unattached_blocking_receipt(blocking_amount = nil)
    blocking_amount ||= self.booking_portal_client.blocking_amount
    Receipt.where(booking_portal_client_id: self.booking_portal_client_id, lead_id: id).in(status: %w[success clearance_pending]).where(booking_detail_id: nil).asc(:token_number).first
  end

  def is_payment_done?
    receipts.where(booking_portal_client_id: self.booking_portal_client_id).where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).present?
  end

  def is_blocking_amount_paid?
    booking = self.first_booking_detail
    booking.present? && booking.status.in?(%w(blocked booked_tentative booked_confirmed))
  end

  def is_booking_price_paid?
    booking = self.first_booking_detail
    booking.present? && booking.status == 'booked_confirmed'
  end

  def is_registration_done?
    booking = self.first_booking_detail
    booking.present? && booking.is_registration_done?
  end

  def total_amount_paid
    receipts.where(status: 'success').sum(:total_amount)
  end

  def total_balance_pending
    booking_details.in(status: ProjectUnit.booking_stages).sum(&:pending_balance) rescue nil
  end

  def total_unattached_balance
    receipts.where(booking_portal_client_id: self.booking_portal_client_id).in(status: %w[success clearance_pending]).where(booking_detail_id: nil).sum(:total_amount)
  end

  def get_search(project_unit_id)
    search = searches.where(booking_portal_client_id: self.booking_portal_client_id)
    search = search.where(project_unit_id: project_unit_id) if project_unit_id.present?
    search = search.desc(:created_at).first
    search = Search.create(lead: self, user: user, booking_portal_client_id: self.booking_portal_client.id) if search.blank?
    search
  end

  def name
    "#{first_name} #{last_name}"
  end

  # Used in incentive invoice
  alias :name_in_invoice :name
  alias :invoiceable_manager :manager
  alias :invoiceable_date :created_at

  def search_name
    "#{name} - #{email} - #{phone} (#{project_name})"
  end

  def ds_name(current_user)
    ds_name = "#{name}"
    ds_name << " - #{masked_email(current_user)}" if email.present?
    ds_name << " - #{masked_phone(current_user)}" if phone.present?
    ds_name << " (#{project_name})" if project_name.present?
    return ds_name
  end

  def active_cp_lead_activities
    self.cp_lead_activities.where(expiry_date: { '$gte': Date.current })
  end

  def lead_validity_period
    activity = self.active_cp_lead_activities.first
    activity.present? ? "#{(activity.expiry_date - Date.current).to_i} Days" : '0 Days'
  end

  def send_payment_link(booking_detail_id = nil, host = nil)
    url = Rails.application.routes.url_helpers
    client = user.booking_portal_client
    if booking_detail_id.present?
      hold_booking_detail = self.booking_details.where(id: booking_detail_id).first
    else
      hold_booking_detail = self.booking_details.where(status: 'hold').first
    end
    if host.present?
      if hold_booking_detail.present? && hold_booking_detail.search && hold_booking_detail.status == "hold"
        self.payment_link = url.checkout_lead_search_url(hold_booking_detail.search, user_login: user.email, user_token: user.authentication_token, booking_portal_client_id: client.id.to_s, project_id: self.project_id.to_s, host: host)
      else
        self.payment_link = url.dashboard_url("remote-state": url.new_buyer_receipt_path(booking_detail_id: booking_detail_id), user_login: user.email, user_token: user.authentication_token, booking_portal_client_id: client.id.to_s, project_id: self.project_id.to_s, host: host)
      end
      #
      # Send email with payment link
      email_template = ::Template::EmailTemplate.where(booking_portal_client_id: self.booking_portal_client_id, name: "payment_link", project_id: self.project_id).first
      if email_template.present?
        email = Email.create!({
          booking_portal_client_id: client.id,
          body: ERB.new(client.email_header).result(client.get_binding) + email_template.parsed_content(self) + ERB.new(client.email_footer).result(client.get_binding),
          subject: email_template.parsed_subject(self),
          email_template_id: email_template.id,
          to: [ self.email ],
          cc: client.notification_email.to_s.split(',').map(&:strip),
          triggered_by_id: id,
          triggered_by_type: self.class.to_s
        })
        email.sent!
      end
      # Send sms with link for payment
      sms_template = Template::SmsTemplate.where(booking_portal_client_id: self.booking_portal_client_id, name: "payment_link", project_id: self.project_id).first
      sms_body = sms_template.parsed_content(self) if sms_template.present?
      if sms_template.present?
        Sms.create!({
          booking_portal_client_id: client.id,
          body: sms_body,
          to: [self.phone],
          triggered_by_id: id,
          triggered_by_type: self.class.to_s
        }) unless sms_body.blank?
      end
    end
  end

  def kyc_ready?
    user_kyc_ids.present?
  end

  def sync_with_selldo params={}
    if lead.update_attributes(params)
      @crm_base = Crm::Base.where(booking_portal_client_id: self.booking_portal_client_id, domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      selldo_api = Crm::Api::Put.where(resource_class: 'Lead', base_id: @crm_base.id, is_active: true).first if @crm_base.present?
      selldo_api.execute(self)
    end
  end

  def arrived_sitevist
    site_visits.where(booking_portal_client_id: self.booking_portal_client_id, status: 'arrived', _id: self.current_site_visit_id).order(created_at: :desc).first
  end

  def is_revisit?
    self.site_visits.where(booking_portal_client_id: self.booking_portal_client_id, status: "conducted").present?
  end

  def kyc_required_before_booking?
    !kyc_ready? && project.kyc_required_before_booking?
  end

  def kyc_required_during_booking?
    !kyc_ready? && project.kyc_required_during_booking?
  end

  def check_for_lead_conflict
    if self.manager.present?
      lead_conflict_on = self.booking_portal_client.enable_lead_conflicts
      if lead_conflict_on == 'client_level'
        # same lead cannot be added by another partner in any project
        lead = Lead.where(user_id: self.user.id, booking_portal_client_id: self.booking_portal_client.id)
        if lead.present?
          unless (lead.distinct(:manager_id).count <= 1 && lead.first.try(:manager_id) == self.manager_id)
            self.errors.add(:base, I18n.t('mongoid.attributes.lead.errors.lead_registered_with_client'))
          else
            if lead.where(project_id: self.project_id).present?
              self.errors.add(:base, I18n.t('mongoid.attributes.lead.errors.lead_registered_with_project'))
            end
          end
        end
      elsif lead_conflict_on == 'project_level'
        # same lead cannot be added by partner in that project
        lead = Lead.where(project_id: self.project.id, user_id: self.user.id, booking_portal_client: self.booking_portal_client.id).first
        self.errors.add(:base, I18n.t('mongoid.attributes.lead.errors.lead_registered_with_project')) if lead.present?
      end
    end
  end

  class << self

    def user_based_scope(user, params = {})
      custom_scope = {}
      project_ids = (params[:current_project_id].present? ? [params[:current_project_id]] : user.project_ids)
      case user.role.to_sym
      when :channel_partner
        custom_scope = { manager_id: user.id, channel_partner_id: user.channel_partner_id }
      when :cp_owner
        custom_scope = { channel_partner_id: user.channel_partner_id }
      when :cp
        #channel_partner_ids = User.where(role: 'channel_partner', manager_id: user.id).distinct(:id)
        #lead_ids = CpLeadActivity.in(user_id: channel_partner_ids).distinct(:lead_id)
        #custom_scope = {_id: { '$in': lead_ids } }
        custom_scope = {}
      when :cp_admin
        #channel_partner_manager_ids = User.where(role: 'cp', manager_id: user.id).distinct(:id)
        #channel_partner_ids = User.in(manager_id: channel_partner_manager_ids).distinct(:id)
        #lead_ids = CpLeadActivity.in(user_id: channel_partner_ids).distinct(:lead_id)
        #custom_scope = {_id: { '$in': lead_ids } }
        custom_scope = {}
      when :admin
        custom_scope = { }
      when :sales
        custom_scope = { }
      when :sales_admin
        custom_scope = { }
      when :superadmin
        custom_scope = { }
      when :gre
        custom_scope = { }
      end
      custom_scope = { user_id: params[:user_id] } if params[:user_id].present?
      custom_scope = { user_id: user.id } if user.buyer?

      if !user.role.in?(User::ALL_PROJECT_ACCESS) || params[:current_project_id].present?
        custom_scope.merge!({project_id: { "$in": project_ids } })
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end

  end
end
