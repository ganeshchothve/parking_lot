require 'active_model_otp'
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ActiveModel::OneTimePassword
  include InsertionStringMethods
  include ApplicationHelper
  include CrmIntegration
  extend FilterByCriteria
  extend ApplicationHelper
  include SalesUserStateMachine
  include DetailsMaskable
  include IncentiveSchemeAutoApplication
  include UserStatusInCompanyStateMachine
  extend DocumentsConcern

  # Constants
  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  ALLOWED_UTM_KEYS = %i[utm_campaign utm_source utm_sub_source utm_content utm_medium utm_term]
  BUYER_ROLES = %w[user employee_user management_user]
  ADMIN_ROLES = %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner gre billing_team team_lead account_manager_head account_manager cp_owner dev_sourcing_manager]
  CHANNEL_PARTNER_USERS = %w[cp cp_admin channel_partner cp_owner]
  ALL_PROJECT_ACCESS = %w[superadmin admin cp cp_admin billing_team] + User::BUYER_ROLES
  # SELECTED_PROJECT_ACCESS = %w[sales sales_admin gre crm team_lead dev_sourcing_manager account_manager account_manager_head]
  SALES_USER = %w[sales sales_admin]
  COMPANY_USERS = %w[employee_user management_user]
  # Added different types of documents which are uploaded on User
  DOCUMENT_TYPES = %w[home_loan_application_form photo_identity_proof residence_address_proof residence_ownership_proof income_proof job_continuity_proof bank_statement advance_processing_cheque financial_documents first_page_co_branding last_page_co_branding co_branded_asset]
  TEAM_LEAD_DASHBOARD_ACCESS_USERS = %w[team_lead gre]
  KYLAS_MARKETPALCE_USERS = %w[admin sales gre sales_admin channel_partner cp_owner superadmin].freeze
  KYLAS_CUSTOM_FIELDS_ENTITIES = %w[lead deal meeting].freeze
  CLIENT_SCOPED_ROLES = (%w[channel_partner cp_owner] + User::BUYER_ROLES).freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable, :database_authenticatable, :recoverable, :rememberable, :trackable, :confirmable, :timeoutable, :password_archivable, :omniauthable, :omniauth_providers => [:selldo], authentication_keys: {login: true, booking_portal_client_id: false, project_id: false}, reset_password_keys: [:login, :booking_portal_client_id, :project_id] #:lockable,:expirable,:session_limitable,:password_expirable
  attr_accessor :temporary_password, :payment_link, :temp_manager_id, :company_name, :project_id, :sender_email, :booking_portal_domains

  ## Database authenticatable
  field :first_name, type: String, default: ''
  field :last_name, type: String, default: ''
  field :email, type: String, default: ''
  field :phone, type: String, default: ''
  field :lead_id, type: String
  field :role, type: String, default: 'user'
  field :allowed_bookings, type: Integer
  field :manager_change_reason, type: String
  field :referenced_manager_ids, type: Array, default: []
  field :rera_id, type: String
  field :mixpanel_id, type: String
  field :time_zone, type: String, default: 'Mumbai'
  field :erp_id, type: String, default: ''
  field :utm_params, type: Hash, default: {} # {"campaign": '' ,"source": '',"sub_source": '',"medium": '',"term": '',"content": ''}
  field :enable_communication, type: Hash, default: { "email": true, "sms": true }
  field :premium,type: Boolean, default: false
  field :rejection_reason, type: String

  field :encrypted_password, type: String, default: ''

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,         type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,    type: String # Only if using reconfirmable
  field :iris_confirmation, type: Boolean, default: false

  ## Token Authenticatable
  acts_as_token_authenticatable
  field :authentication_token

  field :is_active, type: Boolean, default: true
  field :enable_live_inventory, type: Boolean, default: false

  ## Lockable
  field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  field :locked_at,       type: Time

  # field for active_model_otp
  field :otp_secret_key
  field :referral_code, type: String

  ## Password expirable
  field :password_changed_at, type: DateTime

  ## Password archivable
  field :password_archivable_type, type: String
  field :password_archivable_id, type: String
  field :password_salt, type: String # Optional. bcrypt stores the salt in the encrypted password field so this column may not be necessary.

  ## Session limitable
  field :unique_session_id, type: String
  field :uniq_user_agent, type: String

  ## Expirable
  field :last_activity_at, type: DateTime
  field :expired_at, type: DateTime

  ## Paranoid verifiable
  field :paranoid_verification_code, type: String
  field :paranoid_verification_attempt, type: Integer, default: 0
  field :paranoid_verified_at, type: DateTime

  field :selldo_uid, type: String
  field :selldo_access_token, type: String

  field :temporarily_blocked, type: Boolean, default: false
  field :unblock_at, type: Date

  # For scoping user with roles: (sales, sales_admin, crm, gre, billing_team) under projects
  # For channel partner users, using interested projects association for scoping under projects
  field :project_ids, type: Array, default: []
  field :client_ids, type: Array, default: []
  field :cp_code, type: String

  field :upi_id, type: String

  field :referred_on, type: DateTime
  field :register_in_cp_company_token, type: String
  # For channel partners, gets copied from partner company
  field :category, type: String

  # Kylas Integration Code
  field :kylas_access_token, type: String
  field :kylas_refresh_token, type: String
  field :kylas_user_id, type: String
  field :kylas_access_token_expires_at, type: DateTime
  field :kylas_contact_id, type: String
  field :is_active_in_kylas, type: Boolean, default: true
  field :tenant_owner, type: Boolean, default: false

  # Kylas Custom Fields options values fields
  field :kylas_custom_fields_option_id, type: Hash, default: {}


  ## Security questionable

  delegate :name, :role, :role?, :email, to: :manager, prefix: true, allow_nil: true
  delegate :name, :role, :email, to: :confirmed_by, prefix: true, allow_nil: true

  def self.otp_length
    6
  end

  has_one_time_password length: User.otp_length
  default_scope -> { desc(:created_at) }

  include OtpLoginHelperMethods

  enable_audit(
    indexed_fields: %i[first_name last_name],
    audit_fields: %i[status lead_id role allowed_bookings manager_id referenced_manager_ids rera_id mixpanel_id email phone],
    reference_ids_without_associations: [
      { field: 'referenced_manager_ids', klass: 'ChannelPartner' }
    ]
  )

  # key to handle both phone or email as a login
  attr_accessor :login, :login_otp

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :users, optional: true
  belongs_to :referred_by, class_name: 'User', optional: true
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :confirmed_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :tier, optional: true  # for associating channel partner users with different tiers.
  belongs_to :selected_lead, class_name: 'Lead', optional: true
  belongs_to :selected_project, class_name: 'Project', optional: true
  belongs_to :selected_client, class_name: 'Client', optional: true
  belongs_to :temp_channel_partner, class_name: 'ChannelPartner', optional: true
  has_many :leads
  has_many :receipts
  has_many :project_units
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :invoices, as: :invoiceable
  has_many :searches
  has_many :received_smses, class_name: 'Sms', inverse_of: :recipient
  has_many :received_whatsapps, class_name: 'Whatsapp', inverse_of: :recipient
  has_many :assets, as: :assetable
  has_and_belongs_to_many :received_emails, class_name: 'Email', inverse_of: :recipients
  has_and_belongs_to_many :cced_emails, class_name: 'Email', inverse_of: :cc_recipients
  has_many :cp_lead_activities
  has_and_belongs_to_many :meetings
  has_many :interested_projects  # Channel partners can subscribe to new projects through this
  has_many :fund_accounts

  has_many :notes, as: :notable

  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :emails, as: :triggered_by, class_name: 'Email'
  has_many :whatsapps, as: :triggered_by, class_name: 'Whatsapp'
  has_many :referrals, class_name: 'User', foreign_key: :referred_by_id, inverse_of: :referred_by
  has_many :site_visits
  has_and_belongs_to_many :schemes
  has_many :logs, class_name: 'SyncLog', inverse_of: :user_reference
  embeds_many :portal_stages
  embeds_many :user_notification_tokens

  accepts_nested_attributes_for :portal_stages, :user_notification_tokens, reject_if: :all_blank
  accepts_nested_attributes_for :interested_projects, reject_if: :all_blank

  validates :role, presence: true
  validates :phone, presence: true, if: proc { |user| user.role.in?(%w(cp_owner channel_partner)) }
  #validates :first_name, :last_name, name: true, allow_blank: true
  validate :phone_or_email_required, if: proc { |user| user.phone.blank? && user.email.blank? }
  # validates :phone, :email, uniqueness: { allow_blank: true }
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile mobile fixed_line premium_rate] }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP } , allow_blank: true
  validates :allowed_bookings, presence: true, if: proc { |user| user.buyer? }
  # validates :rera_id, presence: true, if: proc { |user| user.role?('channel_partner') } #TO-DO Done for Runwal to revert for generic
  #validates :rera_id, uniqueness: true, allow_blank: true
  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: Devise.password_length, allow_blank: true
  validates :role, inclusion: { in: proc { |user| User.available_roles(user.booking_portal_client) } }
  validates :lead_id, uniqueness: true, if: proc { |user| user.buyer? }, allow_blank: true
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :manager_change_reason_present?
  validate :password_complexity
  validate :phone_email_uniqueness
  validates :booking_portal_client_id, presence: true, unless: proc { |user| user.role?(:superadmin) }
  validates :kylas_user_id, uniqueness: true, allow_blank: true
  validate :need_at_least_one_admin
  validate :cannot_unset_kylas_user_id

  # scopes needed by filter
  # scope :filter_by_confirmation, ->(confirmation) { confirmation.eql?('not_confirmed') ? where(confirmed_at: nil) : where(confirmed_at: { "$ne": nil }) }
  scope :filter_by__id, ->(_id) { where(id: _id) }
  scope :filter_by_confirmation, ->(confirmation) { confirmation == 'true' ? where(confirmed_at: { "$ne": nil }) : where(confirmed_at: nil)}
  scope :filter_by_is_active, ->(is_active) { is_active.eql?("true") ? where(is_active: true)
    : where(is_active: false)}
  scope :filter_by_channel_partner_id, ->(channel_partner_id) {where(channel_partner_id: channel_partner_id) }
  scope :filter_by_category, ->(category) {where(category: category) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where({ '$and' => ["$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] ] }) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_role, ->(_role) { _role.is_a?(Array) ? where( role: { "$in": _role }) : where(role: _role.as_json) }

  scope :filter_by_role_nin, ->(_role) { _role.is_a?(Array) ? where( role: { "$nin": _role } ) : where(role: _role.as_json) }
  scope :buyers, -> { where(role: {'$in' => BUYER_ROLES } )}
  scope :filter_by_userwise_project_ids, ->(user) { self.in(project_ids: user.project_ids) if user.try(:project_ids).present? }
  scope :filter_by_sales_status, ->(sales_status){ sales_status.is_a?(Array) ? where( sales_status: { "$in": sales_status }) : where(sales_status: sales_status.as_json) }
  scope :filter_by_booking_portal_client_id, ->(booking_portal_client_id) { where(booking_portal_client_id: booking_portal_client_id) }
  scope :filter_by_user_status_in_company, ->(user_status_in_company){ user_status_in_company.is_a?(Array) ? where( user_status_in_company: { "$in": user_status_in_company }) : where(user_status_in_company: user_status_in_company.as_json) }
  scope :incentive_eligible, ->(category) do
    if category == 'referral'
      nin(referred_by_id: ['', nil]).in(role: BUYER_ROLES + %w(channel_partner cp_owner))
    else
      none
    end
  end

  scope :filter_by_created_by, ->(_created_by) do
    if _created_by == 'direct'
      where('$or' => [{'$expr' => {'$eq' => ['$created_by_id', "$_id"] } }, { created_by_id: nil } ])
    else
      where(created_by_id: _created_by)
    end
  end
  scope :filter_by_receipts, ->(receipts) do
    user_ids = Receipt.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).distinct(:user_id)
    if user_ids.present?
      if receipts == 'yes'
        where(id: { '$in': user_ids })
      elsif receipts == 'no'
        where(id: { '$nin': user_ids })
      end
    end
  end
  scope :filter_by_cp_reference_id, ->(reference_id) do
    if reference_id.present?
      third_party_references = []
      reference_id.each do |key, value|
        next if (key.blank? || value.blank?)
        crm_id = (BSON.ObjectId(key) rescue "")
        third_party_references << {"third_party_references.crm_id": crm_id, "third_party_references.reference_id": value}
      end
      if third_party_references.present?
        where("$or": third_party_references)
      end
    end
  end
  scope :filter_by_cp_code, ->(cp_code) do
      channel_partner = ChannelPartner.where(cp_code: cp_code)
      if channel_partner.present?
        where(id: {"$in": channel_partner.pluck(:associated_user_id)})
      else
        User.none
      end
  end
  scope :filter_by_interested_project, ->(project_ids) do
    if project_ids.is_a?(Array)
      all.in(id: InterestedProject.approved.in(project_id: project_ids).pluck(:user_id))
    else
      all.in(id: InterestedProject.approved.where(project_id: project_ids).pluck(:user_id))
    end
  end

  scope :filter_by_interested_project_created_at, ->(date, project) do
    start_date, end_date = date.split(' - ')
    if project.present?
      all.in(id: InterestedProject.approved.where(project_id: project, created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }).distinct(:user_id))
    else
      all.in(id: InterestedProject.approved.where(created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }).distinct(:user_id))
    end
  end


  # This some additional scope which help to fetch record easily.
  # This following methods are
  # buyer which will return all BUYER_ROLES users
  # then each role has own name scope
  scope :buyer, -> { where('role.in': self::BUYER_ROLES )}
  BUYER_ROLES.each do |buyer_roles|
    scope buyer_roles, ->{ where(role: buyer_roles )}
  end
  ADMIN_ROLES.each do |admin_roles|
    scope admin_roles, ->{ where(role: admin_roles )}
  end

  def need_at_least_one_admin
    errors.add(:base, 'Need at least one admin account') if self.role_changed? && self.role_was == 'admin' && User.where(booking_portal_client_id: booking_portal_client_id).ne(id: self.id).admin.first.blank?
  end

  def cannot_unset_kylas_user_id
    errors.add(:kylas_user_id, 'cannot be changed or reset') if self.kylas_user_id_changed? && self.kylas_user_id_was.present?
  end

  # Kylas Auth Code
  def kylas_api_key
    self.booking_portal_client.kylas_api_key
  end

  def kylas_api_key?
    self.booking_portal_client.kylas_api_key.present?
  end

  def access_token_valid?
    (kylas_access_token_expires_at.to_i > DateTime.now.to_i)
  end

  def update_users_and_tenants_details(response)
    user_response = Kylas::UserDetails.new(User.new(
      kylas_access_token: response[:access_token],
      kylas_refresh_token: response[:refresh_token],
      kylas_access_token_expires_at: Time.at(DateTime.now.to_i + response[:expires_in])
    )).call

    if user_response[:success]
      k_user_id = user_response.dig(:data, 'id')
      user = User.where(kylas_user_id: k_user_id).first
      if user.present?
        if self.id == user.id
          save_kylas_user_id(k_user_id, response)
        else
          false
        end
      else
        if self.kylas_user_id.blank?
          save_kylas_user_id(k_user_id, response)
        else
          false
        end
      end
    end
  end

  def fetch_access_token
    return kylas_access_token if access_token_valid?
    app_credentials = booking_portal_client.app_credentials

    response = Kylas::GetAccessToken.new(kylas_refresh_token, app_credentials).call

    return unless response[:success]

    update_tokens_details!(response) if self.persisted?
    kylas_access_token
  end

  def phone_email_uniqueness
    attrs = []
    attrs << {email: self.email} if self.email.present?
    attrs << {phone: self.phone} if self.phone.present?
    if attrs.present?
      if self.role.in?(User::CLIENT_SCOPED_ROLES)
        self.errors.add(:base, 'User with these details already exists') if User.in(role: User::CLIENT_SCOPED_ROLES).ne(id: self.id).where(booking_portal_client_id: self.booking_portal_client_id).or(attrs).present?
      else
        self.errors.add(:base, 'User with these details already exists') if User.nin(role: User::CLIENT_SCOPED_ROLES).ne(id: self.id).or(attrs).present?
      end
    end
  end

  def send_marketplace_token_expired_email
    if kylas_api_key? && !access_token_valid?
      email_template = Template::EmailTemplate.where(name: "marketplace_app_session_expired", booking_portal_client_id: booking_portal_client_id).first
      if email_template.present? && email_template.is_active?
        attrs = {
                  booking_portal_client_id: booking_portal_client_id,
                  subject: email_template.parsed_subject(self),
                  body: email_template.parsed_content(self),
                  email_template_id: email_template.id,
                  recipients: [ self ],
                  triggered_by_id: id,
                  triggered_by_type: self.class.to_s
                }
        email = Email.create!(attrs)
        email.sent!
      end
    end
  end

  def tentative_incentive_eligible?(category=nil)
    if category.present?
      if category == 'referral'
        referred_by_id.present? && (self.buyer? || self.role.in?(%w(channel_partner cp_owner)))
      else
        false
      end
    else
      _tentative_incentive_eligible?
    end
  end

  def initials
    "#{(first_name[0] rescue "").capitalize}#{(last_name[0] rescue "").capitalize}"
  end

  def draft_incentive_eligible?(category=nil)
    if category.present?
      if category == 'referral'
        referred_by_id.present? && (self.buyer? || self.role.in?(%w(channel_partner cp_owner)))
      else
        false
      end
    else
      _draft_incentive_eligible?
    end
  end

  def phone_or_email_required
    errors.add(:base, 'Email or Phone is required')
  end

  def status
    if role?('sales')
      sales_status
    elsif ["channel_partner","cp_owner"].include?(role)
      user_status_in_company
    else
      nil
    end
  end

  def unblock_lead!(tag = false)
    if self.temporarily_blocked
      self.temporarily_blocked = false
      self.unblock_at = nil
      if tag
        self.manager_change_reason = "Payment done through #{manager_name} manager"
      else
        self.iris_confirmation = false
        self.manager_change_reason = "Lead unblocked"
        self.manager_id = nil
      end
    else
      self.iris_confirmation = true if tag
    end
    self.save
  end

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    if password.blank? || password =~ /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,16}$/
      arr = []
      arr << ::Regexp.new(first_name, true) if first_name.present? && first_name.length >= 3
      arr << ::Regexp.new(last_name, true) if last_name.present? && last_name.length >= 3
      re = ::Regexp.union(arr)
      if password !~ re
        true
      else
        errors.add :password, I18n.t("mongoid.attributes.user/password.name")
      end
    else
      errors.add :password, I18n.t("mongoid.attributes.user/password.length")
    end
  end

  def set_utm_params(cookies)
    ALLOWED_UTM_KEYS.each do |key|
      utm_params[key] = cookies[key] if cookies[key].present?
    end
    utm_params
  end

  def total_amount_paid
    receipts.where(status: 'success').sum(:total_amount)
  end

  def portal_stage
    portal_stages.desc(:updated_at).first
  end

  def set_portal_stage_and_push_in_crm
    if self.role.in?(%w(cp_owner channel_partner))
      stage = self.channel_partner&.status
      priority = PortalStagePriority.where(booking_portal_client_id: self.booking_portal_client_id, role: 'channel_partner').collect{|x| [x.stage, x.priority]}.to_h
      if stage.present? && priority[stage].present?
        self.portal_stages.where(stage:  stage).present? ? self.portal_stages.where(stage:  stage).first.set(updated_at: Time.now, priority: priority[stage]) : self.portal_stages << PortalStage.new(booking_portal_client_id: self.booking_portal_client_id, stage: stage, priority: priority[stage])
        #push_to_crm = self.booking_portal_client.external_api_integration?
        #if push_to_crm
        #  Crm::Api::Put.where(resource_class: 'User', is_active: true).each do |api|
        #    api.execute(self)
        #  end
        #end
      end
    end
  end

  def update_onesignal_external_user_id(player_id)
    if Rails.env.production?
      Communication::OneSignal::ExternalUserIdUpdateWorker.perform_async(self.id.to_s, player_id)
    else
      Communication::OneSignal::ExternalUserIdUpdateWorker.new.perform(self.id.to_s, player_id)
    end
  end

  def active_bookings
    booking_details.in(status: BookingDetail::BOOKING_STAGES)
  end

  def total_balance_pending
    booking_details.in(status: ProjectUnit.booking_stages).sum(&:pending_balance)
  end

  #
  # This function check the booking limit, any buyer can book only limited booking which is defined on allowed_bookings.
  #
  #
  # @return [Boolean]
  #
  def can_book_more_booking?
    self.booking_details.in(status: BookingDetail::BOOKING_STAGES ).count > self.allowed_bookings
  end

  def total_unattached_balance
    receipts.in(status: %w[success clearance_pending]).where(booking_detail_id: nil).sum(:total_amount)
  end

  def kyc_ready?
    user_kyc_ids.present?
  end

  def buyer?
    BUYER_ROLES.include?(role)
  end

  def role?(role)
    (self.role.to_s == role.to_s)
  end

  def confirmed_by_self?
    self.confirmed_by_id.blank? || self.confirmed_by_id == self.id
  end

  # new function to set the password without knowing the current
  # password used in our confirmation controller.
  def attempt_set_password(params)
    p = {}
    p[:password] = params[:password]
    p[:password_confirmation] = params[:password_confirmation]
    update_attributes(p)
  end

  # new function to return whether a password has been set
  def has_no_password?
    encrypted_password.blank?
  end

  def password_match?
    errors[:password] << "can't be blank" if password.blank?
    errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
    errors[:password_confirmation] << 'does not match password' if password != password_confirmation
    password == password_confirmation && !password.blank?
  end

  # Devise::Models:unless_confirmed` method doesn't exist in Devise 2.0.0 anymore.
  # Instead you should use `pending_any_confirmation`.
  def only_if_unconfirmed
    pending_any_confirmation { yield }
  end

  def password_required?
    if !persisted?
      false
    else
      !password.nil? || !password_confirmation.nil?
    end
  end

  def ds_name(current_user = nil)
    if buyer? && maskable_field?(current_user)
      "#{name} - #{masked_email(current_user)} - #{masked_phone(current_user)}"
    else
      search_name
    end
  end

  def search_name
    "#{name} - #{email} - #{phone}"
  end

  def generate_referral_code
    if (self.buyer? || self.role.in?(%w(cp_owner channel_partner))) && self.referral_code.blank?
      self.referral_code = "#{SecureRandom.hex(3)[0..-2]}"
    end
  end

  def generate_cp_code
    if ['channel_partner', 'cp_owner'].include?(self.role) && self.cp_code.blank?
      self.cp_code = self.channel_partner&.cp_code.present? ? self.channel_partner&.cp_code : "#{SecureRandom.hex(3)[0..-2]}"
    end
  end

  def dashboard_url
    url = Rails.application.routes.url_helpers
    host = booking_portal_client.base_domain
    port = Rails.application.config.action_mailer.default_url_options[:port].to_i
    host = (port == 443 ? 'https://' : 'http://') + host
    host += (port == 443 || port == 80 || port == 0 ? '' : ":#{port}")
    url.dashboard_url(user_email: email, user_token: authentication_token, host: host)
  end

  # GENERICTODO: handle this with a way to replace urls in SMS or Email Templates
  def confirmation_url
    url = Rails.application.routes.url_helpers
    host = booking_portal_client.base_domain
    port = Rails.application.config.action_mailer.default_url_options[:port].to_i
    host = (port == 443 ? 'https://' : 'http://') + host
    host += (port == 443 || port == 80 || port == 0 ? '' : ":#{port}")
    if self.confirmed? && self.buyer?
      url.iris_confirm_buyer_user_url(self, manager_id: temp_manager_id, user_email: email, user_token: authentication_token, host: host)
    else
      url.user_confirmation_url(confirmation_token: confirmation_token, manager_id: temp_manager_id, host: host)
    end

  end

  def name
    str = _name
    if role.in?(%w(cp_owner channel_partner))
      cp = self.channel_partner
      str += " (#{cp.company_name})" if cp.present? && cp.company_name.present?
    end
    str
  end

  def _name
    "#{first_name} #{last_name}"
  end

  alias :resource_name :name
  # Used in Incentive Invoice
  alias :name_in_invoice :name
  alias :invoiceable_manager :referred_by
  alias :invoiceable_date :referred_on

  # Find incentive schemes
  def find_incentive_schemes(category)
    tier_id = referred_by&.tier_id
    incentive_schemes = ::IncentiveScheme.approved.where(booking_portal_client_id: self.booking_portal_client_id, resource_class: self.class.to_s, category: category, auto_apply: true).lte(starts_on: invoiceable_date).gte(ends_on: invoiceable_date)
    # Find tier level scheme
    if tier_id
      incentive_schemes = incentive_schemes.where(booking_portal_client_id: self.booking_portal_client_id, tier_id: tier_id)
    end
    incentive_schemes
  end

  # Find all the resources for a channel partner that fall under this scheme
  def find_all_resources_for_scheme(i_scheme)
    resources = self.class.incentive_eligible(i_scheme.category).where(booking_portal_client_id: self.booking_portal_client_id, :"incentive_scheme_data.#{i_scheme.id.to_s}".exists => true, referred_by_id: self.referred_by_id).gte(scheduled_on: i_scheme.starts_on).lte(scheduled_on: i_scheme.ends_on)
    self.class.or(resources.selector, {id: self.id}).where(booking_portal_client_id: self.booking_portal_client_id)
  end

  def login
    @login || phone || email
  end

  def active_for_authentication?
    out = super && is_active && is_active_in_kylas?
    out &&= self.booking_portal_client.enable_channel_partners? if self.role.in?(%w(channel_partner cp_owner))
    out
  end

  def inactive_message
    is_active ? super : (sign_in_count.zero? ? :inactive : :is_active)
  end

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  def get_search(project_unit_id)
    search = searches.where(booking_portal_client_id: self.booking_portal_client_id)
    search = search.where(project_unit_id: project_unit_id) if project_unit_id.present?
    search = search.desc(:created_at).first
    search = Search.create(user: self, booking_portal_client_id: self.booking_portal_client_id) if search.blank?
    search
  end

  def unused_user_kyc_ids(project_unit_id)
    user_kyc_ids = user_kycs.collect(&:id)
    booking_details.ne(id: project_unit_id).each do |x|
      user_kyc_ids = user_kyc_ids - [x.primary_user_kyc_id] - x.user_kyc_ids
    end
    user_kyc_ids
  end

  def sync(erp_model, sync_log)
    Api::UserDetailsSync.new(erp_model, self, sync_log).execute
  end

  # This is sub part of send_confirmation_instructions for delay this method is used

  def send_devise_notification(notification, *args)
    message = devise_mailer.send(notification, self, *args)
    if booking_portal_client.email_enabled?
      if message.respond_to?(:deliver_now)
        message.deliver_now
      else
        message.deliver
      end
    end
  end

  def send_confirmation_instructions
    generate_confirmation_token! unless @raw_confirmation_token
    # send_devise_notification(:confirmation_instructions, @raw_confirmation_token, opts)
    devise_mailer.new.send(:devise_sms, self, :confirmation_instructions)

    email_template = Template::EmailTemplate.where(name: "#{role}_confirmation_instructions", booking_portal_client_id: booking_portal_client.id).first
    email_template = Template::EmailTemplate.where(name: "user_confirmation_instructions", booking_portal_client_id: booking_portal_client.id).first if email_template.blank?
    if email_template.present? && email_template.is_active? && (email.present? || unconfirmed_email.present?)
      attrs = {
        booking_portal_client_id: booking_portal_client_id,
        subject: email_template.parsed_subject(self),
        body: email_template.parsed_content(self),
        email_template_id: email_template.id,
        cc: booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        recipients: [ self ],
        triggered_by_id: id,
        triggered_by_type: self.class.to_s
      }
      attrs[:to] = [ unconfirmed_email ] if pending_reconfirmation?
      email = Email.create!(attrs)
      email.sent!
    end
  end

  def is_payment_done?
    receipts.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).present?
  end

  def is_booking_done?
    booking_details.where(status: {"$in": BookingDetail::BOOKING_STAGES}).present?
  end

  def update_selldo_credentials(oauth_data)
    self.selldo_access_token = oauth_data.credentials.token if oauth_data
  end

  alias_method :_booking_portal_client, :booking_portal_client

  def booking_portal_client
    if role?(:superadmin)
      selected_client || Client.first
    else
      _booking_portal_client
    end
  end

  #def push_srd_to_selldo
  #  _selldo_api_key = Client.selldo_api_clients.dig(:website, :api_key)

  #  if self.manager_id.present? && _selldo_api_key.present?
  #    campaign_resp = if self.manager_role?('channel_partner')
  #      { srd: self.booking_portal_client.selldo_cp_srd, sub_source: self.manager_name }
  #    elsif self.manager.role.in?((ADMIN_ROLES - %w(channel_partner)))
  #      { srd: self.booking_portal_client.selldo_default_srd, sub_source: self.manager_name }
  #    end

  #    SelldoLeadUpdater.perform_async(self.id, { action: 'add_campaign_response', api_key: _selldo_api_key }.merge(campaign_resp))
  #  end
  #end

  # Class Methods
  class << self

    def build_criteria(params = {})
      criteria = super(params)
      criteria = criteria.filter_by_interested_project_created_at(params[:interested_project_created_at], params.dig(:fltrs, :interested_project)) if params[:interested_project_created_at].present? && self.respond_to?('filter_by_interested_project_created_at')
      criteria = criteria.where(role: { "$ne": 'superadmin' }) unless criteria.selector.has_key?('role')
      criteria
    end

    def buyer_roles(client = nil)
      if client.present? && client.enable_company_users?
        BUYER_ROLES
      else
        ['user']
      end
    end

    def available_roles(client)
      roles = ADMIN_ROLES + BUYER_ROLES
      roles -= CHANNEL_PARTNER_USERS unless client.try(:enable_channel_partners?)
      roles -= COMPANY_USERS unless client.try(:enable_company_users?)
      roles
    end

    # This method is used to find user for reset_password using reset_password_keys
    # Method overriden to compare reset_password_keys with params
    def find_or_initialize_with_errors(required_attributes, attributes, error=:invalid) #:nodoc:
      attributes = if attributes.respond_to? :permit!
        attributes.slice(*required_attributes).permit!.to_h.with_indifferent_access
      else
        attributes.with_indifferent_access.slice(*required_attributes)
      end

      # here overriden code
      attributes.delete_if { |key, value| value.blank? && authentication_keys[key.to_sym] }

      if attributes.size == required_attributes.size
        record = find_first_by_auth_conditions(attributes)
      end

      unless record
        record = new

        required_attributes.each do |key|
          value = attributes[key]
          record.send("#{key}=", value)
          record.errors.add(key, value.present? ? error : :blank)
        end
      end

      record
    end

    def find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)
      login = conditions.delete(:email) if login.blank? && conditions.key?(:email)
      login = conditions.delete(:phone) if login.blank? && conditions.key?(:phone)
      if login.blank? && warden_conditions[:confirmation_token].present?
        confirmation_token = warden_conditions.delete(:confirmation_token)
        where(confirmation_token: confirmation_token).first
      elsif login.blank? && warden_conditions[:reset_password_token].present?
        reset_password_token = warden_conditions.delete(:reset_password_token)
        where(reset_password_token: reset_password_token).first
      elsif login.present?
        auth_conditions = [{ phone: login }, { email: login }]
        if warden_conditions[:project_id].present?
          or_conds = []
          or_conds << {
            "$or": [
              { booking_portal_client_id: warden_conditions[:booking_portal_client_id], '$or': auth_conditions, role: {"$nin": ALL_PROJECT_ACCESS}, project_ids: BSON::ObjectId(warden_conditions[:project_id]) },
              { booking_portal_client_id: warden_conditions[:booking_portal_client_id], '$or': auth_conditions, role: {"$in": ALL_PROJECT_ACCESS}},
              { booking_portal_client_id: warden_conditions[:booking_portal_client_id], '$or': auth_conditions, role: {"$in": BUYER_ROLES}}
            ]
          }
          or_conds << { role: 'superadmin', '$or': auth_conditions, client_ids: warden_conditions[:booking_portal_client_id] }
          user_criteria = any_of(or_conds)
        elsif warden_conditions[:booking_portal_client_id].present?
          or_conds = []
          or_conds << { booking_portal_client_id: warden_conditions[:booking_portal_client_id], '$or': auth_conditions }
          or_conds << { role: 'superadmin', '$or': auth_conditions, client_ids: warden_conditions[:booking_portal_client_id] }
          user_criteria = any_of(or_conds)
        else
          user_criteria = any_of(auth_conditions).nin(role: User::CLIENT_SCOPED_ROLES)
        end
        user_criteria.first
      else
        super
      end
    end

    def find_record(login)
      where("function() {return this.phone == '#{login}' || this.email == '#{login}'}")
    end

    def role_based_channel_partners_scope(user, _params = {})
      custom_scope = {}
      if user.role?('cp_admin')
        #cp_ids = User.where(manager_id: user.id).distinct(:id)
        custom_scope = { role: { '$in': %w(channel_partner cp_owner) } } #, manager_id: {"$in": cp_ids}
      elsif user.role?('cp')
        custom_scope = { role: { '$in': %w(channel_partner cp_owner) } } #, manager_id: user.id
      elsif user.role?('cp_owner')
        custom_scope = { role: {'$in': ['channel_partner', 'cp_owner']}, channel_partner_id: user.channel_partner_id }
      elsif ["admin"].include?(user.role)
        custom_scope = { role: { '$in': %w(channel_partner cp_owner) }, booking_portal_client_id: user.booking_portal_client.id }
      elsif ["superadmin"].include?(user.role)
        custom_scope = { role: { '$in': %w(channel_partner cp_owner) }, booking_portal_client_id: user.selected_client_id }
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    end

    def user_based_scope(user, _params = {})
      custom_scope = {}
      project_ids = (_params[:current_project_id].present? ? [_params[:current_project_id]] : user.project_ids)
      if user.role?('channel_partner')
        custom_scope = { role: {"$in": User.buyer_roles(user.booking_portal_client)} }
        custom_scope[:'$or'] = [{manager_id: user.id}, {manager_id: nil, referenced_manager_ids: user.id, iris_confirmation: false}]
      elsif user.role?('cp_owner')
        if user.channel_partner_id.present?
          custom_scope = { role: {'$in': ['channel_partner', 'cp_owner']}, '$or': [{channel_partner_id: user.channel_partner_id}, {temp_channel_partner_id: user.channel_partner_id}] }
        else
          custom_scope = { id: user.id }
        end
      elsif user.role?('crm')
        custom_scope = { role: { "$in": User.buyer_roles(user.booking_portal_client) + %w(channel_partner) } }
      elsif user.role?('sales_admin')
        custom_scope = { role: { "$in": User.buyer_roles(user.booking_portal_client) + %w(channel_partner cp_owner sales) } }
      elsif user.role?('cp_admin')
         custom_scope = { role: { '$in': %w(cp channel_partner cp_owner) } }
      elsif user.role?('cp')
        custom_scope[:'$or'] = [{_id: user.id}, { role: { '$in': %w(channel_partner cp_owner) }, manager_id: user.id }]
      elsif user.role?('billing_team')
        custom_scope = { role: { '$in': %w(channel_partner cp_owner) } }
      elsif user.role.in?(%w(admin))
        custom_scope = { role: { "$ne": 'superadmin' } }
        #custom_scope = { role: { "$ne": 'superadmin', '$in': %w(sales admin sales_admin gre channel_partner cp_owner) } } if user.booking_portal_client.try(:kylas_tenant_id).present?
      elsif user.role.in?(%w(sales))
        # custom_scope = { role: { "$in": User.buyer_roles(user.booking_portal_client) }}
        custom_scope = { role: { "$in": User.buyer_roles(user.booking_portal_client) + %w(channel_partner cp_owner) } }
      elsif user.role.in?(%w(superadmin))
        custom_scope = {  }
        #custom_scope = { role: { '$in': %w(sales admin sales_admin gre channel_partner cp_owner) }} if user.booking_portal_client.try(:kylas_tenant_id).present?
      elsif user.role?('team_lead')|| user.role?('gre')
        custom_scope = { role: 'sales', project_ids: { "$in": project_ids }}
      end
      custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
      custom_scope
    end

    def find_or_create_for_selldo_oauth(oauth_data)
      matcher = {}
      matcher[:email] = oauth_data.info.email
      role = case oauth_data.extra.role.try(:to_sym)
             when :sales, :pre_sales
               'sales'
             when :admin
               'admin'
             end
      if role
        client = Client.where(selldo_client_id: oauth_data.extra.client_id).first
        user = User.find_or_initialize_by(matcher).tap do |user|
          user.password = Devise.friendly_token[0,15] + %w(! @ # $ % ^ & * ~).fetch(rand(8)) if user.has_no_password?
          user.selldo_uid ||= oauth_data.uid
          user.first_name = oauth_data.extra.first_name if user.first_name.blank?
          user.last_name = oauth_data.extra.last_name if user.last_name.blank?
          user.phone = oauth_data.extra.phone if user.phone.blank?
          user.booking_portal_client ||= client
          user.confirmed_at = Time.now unless user.confirmed?
          user.role = role
        end
        if user.save!
          user.update_selldo_credentials(oauth_data)
          user
        end
      else
        User.where(matcher).first
      end
    end

    def doc_types(client)
      if client.try(:launchpad_portal)
        DOCUMENT_TYPES
      else
        DOCUMENT_TYPES - %w[first_page_co_branding last_page_co_branding co_branded_asset]
      end
    end
  end

  def active_channel_partner?
    if self.role.in?(%w(cp_owner channel_partner))
      #channel_partner = associated_channel_partner
      return channel_partner.present? && channel_partner.status == 'active'
    else
      return true
    end
  end

  def in_masked_details_user_group?
    role.in?(booking_portal_client.mask_lead_data_for_roles)
  end

  protected

  def send_confirmation_notification?
    confirmation_required? && !@skip_confirmation_notification && (self.email.present? || self.phone.present?)
  end

  private

  def manager_change_reason_present?
    if role.in?(BUYER_ROLES) && persisted? && manager_id_changed? && manager_change_reason.blank?
      errors.add :manager_change_reason, 'is required'
    end
  end

  def update_tokens_details!(response = {})
    return if response.blank?

    update(
      kylas_access_token: response[:access_token],
      kylas_refresh_token: response[:refresh_token],
      kylas_access_token_expires_at: Time.at(DateTime.now.to_i + response[:expires_in])
    )
  end

  def save_kylas_user_id(k_user_id, response)
    if self.update(kylas_user_id: k_user_id)
      if update_tokens_details!(response)
        fetch_and_save_kylas_tenant_id
      else
        false
      end
    else
      false
    end
  end

  def fetch_and_save_kylas_tenant_id
    return if kylas_access_token.blank?

    begin
      response = Kylas::TenantDetails.new(self).call
      if response[:success]
        self.booking_portal_client.update(kylas_tenant_id: response.dig(:data, 'id'))
      else
        false
      end
    rescue StandardError
      Rails.logger.error 'Kylas::TenantDetails - StandardError'
      false
    end
  end

end
