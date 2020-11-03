require 'active_model_otp'
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ActiveModel::OneTimePassword
  include InsertionStringMethods
  include ApplicationHelper
  # include SyncDetails
  include CrmIntegration
  extend FilterByCriteria
  extend ApplicationHelper

  # Constants
  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  ALLOWED_UTM_KEYS = %i[utm_campaign utm_source utm_sub_source utm_content utm_medium utm_term]
  BUYER_ROLES = %w[user employee_user management_user]
  ADMIN_ROLES = %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner gre]
  CHANNEL_PARTNER_USERS = %w[cp cp_admin channel_partner]
  SALES_USER = %w[sales sales_admin]
  COMPANY_USERS = %w[employee_user management_user]
  # Added different types of documents which are uploaded on User
  DOCUMENT_TYPES = %w[home_loan_application_form photo_identity_proof residence_address_proof residence_ownership_proof income_proof job_continuity_proof bank_statement advance_processing_cheque financial_documents]

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable, :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable, :timeoutable, :password_expirable, :password_archivable, :session_limitable, :expirable, :omniauthable, :omniauth_providers => [:selldo], authentication_keys: [:login]

  attr_accessor :temporary_password, :payment_link, :temp_manager_id

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

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :users
  belongs_to :referred_by, class_name: 'User', optional: true
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :confirmed_by, class_name: 'User', optional: true
  has_many :receipts
  has_many :project_units
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :searches
  has_many :received_smses, class_name: 'Sms', inverse_of: :recipient
  has_many :received_whatsapps, class_name: 'Whatsapp', inverse_of: :recipient
  has_many :assets, as: :assetable
  has_and_belongs_to_many :received_emails, class_name: 'Email', inverse_of: :recipients
  has_and_belongs_to_many :cced_emails, class_name: 'Email', inverse_of: :cc_recipients

  has_many :notes, as: :notable

  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :emails, as: :triggered_by, class_name: 'Email'
  has_many :whatsapps, as: :triggered_by, class_name: 'Whatsapp'
  has_many :referrals, class_name: 'User', foreign_key: :referred_by_id, inverse_of: :referred_by
  has_and_belongs_to_many :schemes
  has_many :logs, class_name: 'SyncLog', inverse_of: :user_reference
  embeds_many :portal_stages
  accepts_nested_attributes_for :portal_stages, reject_if: :all_blank

  validates :first_name, :role, presence: true
  validates :first_name, :last_name, name: true, allow_blank: true

  validate :phone_or_email_required, if: proc { |user| user.phone.blank? && user.email.blank? }
  validates :phone, :email, uniqueness: { allow_blank: true }
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile mobile fixed_line premium_rate] }, allow_blank: true
  validates :allowed_bookings, presence: true, if: proc { |user| user.buyer? }
  validates :rera_id, presence: true, if: proc { |user| user.role?('channel_partner') }
  validates :rera_id, uniqueness: true, allow_blank: true
  validates :role, inclusion: { in: proc { |user| User.available_roles(user.booking_portal_client) } }
  validates :lead_id, uniqueness: true, presence: true, if: proc { |user| user.buyer? }, allow_blank: true
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :manager_change_reason_present?
  validate :password_complexity

  # scopes needed by filter
  scope :filter_by_lead_id, ->(lead_id) { where(lead_id: lead_id) }
  scope :filter_by_confirmation, ->(confirmation) { confirmation.eql?('not_confirmed') ? where(confirmed_at: nil) : where(confirmed_at: { "$ne": nil }) }
  scope :filter_by_manager_id, ->(manager_id) {where(manager_id: manager_id) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where({ '$and' => ["$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] ] }) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_role, ->(_role) { _role.is_a?(Array) ? where( role: { "$in": _role }) : where(role: _role.as_json) }

  scope :filter_by_role_nin, ->(_role) { _role.is_a?(Array) ? where( role: { "$nin": _role } ) : where(role: _role.as_json) }

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
  scope :buyers, -> { where(role: {'$in' => BUYER_ROLES } )}

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

  def phone_or_email_required
    errors.add(:base, 'Email or Phone is required')
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
      arr << ::Regexp.new(first_name, true) if first_name.present?
      arr << ::Regexp.new(last_name, true) if last_name.present?
      re = ::Regexp.union(arr)
      if password !~ re
        true
      else
        errors.add :password, 'should not contain name.'
      end
    else
      errors.add :password, 'Length should be 8-16 characters and include: 1 uppercase, 1 lowercase, 1 digit and 1 special character.'
    end
  end

  def unattached_blocking_receipt(blocking_amount = nil)
    blocking_amount ||= current_client.blocking_amount
    Receipt.where(user_id: id).in(status: %w[success clearance_pending]).where(booking_detail_id: nil).where(total_amount: { "$gte": blocking_amount }).asc(:token_number).first
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

  def ds_name
    "#{name} - #{email} - #{phone}"
  end

  def generate_referral_code
    if self.buyer? && self.referral_code.blank?
      self.referral_code = "#{self.booking_portal_client.name[0..1].upcase}-#{SecureRandom.hex(4)}"
    else
      self.referral_code
    end
  end


  def dashboard_url
    url = Rails.application.routes.url_helpers
    host = Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port].to_i
    host = (port == 443 ? 'https://' : 'http://') + host
    host += (port == 443 || port == 80 || port == 0 ? '' : ":#{port}")
    url.dashboard_url(user_email: email, user_token: authentication_token, host: host)
  end

  # GENERICTODO: handle this with a way to replace urls in SMS or Email Templates
  def confirmation_url
    url = Rails.application.routes.url_helpers
    host = Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port].to_i
    host = (port == 443 ? 'https://' : 'http://') + host
    host += (port == 443 || port == 80 || port == 0 ? '' : ":#{port}")
    if self.confirmed? && self.buyer?
      url.iris_confirm_buyer_user_url(self, manager_id: temp_manager_id, user_email: email, user_token: authentication_token)
    else
      url.user_confirmation_url(confirmation_token: confirmation_token, manager_id: temp_manager_id, host: host)
    end

  end

  def name
    str = "#{first_name} #{last_name}"
    if role?('channel_partner')
      cp = ChannelPartner.where(associated_user_id: id).first
      str += " (#{cp.company_name})" if cp.present? && cp.company_name.present?
    end
    str
  end

  alias :resource_name :name

  def login
    @login || phone || email
  end

  def active_for_authentication?
    super && is_active
  end

  def inactive_message
    is_active ? super : :is_active
  end

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  def get_search(project_unit_id)
    search = searches
    search = search.where(project_unit_id: project_unit_id) if project_unit_id.present?
    search = search.desc(:created_at).first
    search = Search.create(user: self) if search.blank?
    search
  end

  def unused_user_kyc_ids(project_unit_id)
    if booking_portal_client.allow_multiple_bookings_per_user_kyc?
      user_kyc_ids = user_kycs.collect(&:id)
    else
      user_kyc_ids = user_kycs.collect(&:id)
      booking_details.ne(id: project_unit_id).each do |x|
        user_kyc_ids = user_kyc_ids - [x.primary_user_kyc_id] - x.user_kyc_ids
      end
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

    if email.present? || unconfirmed_email.present?
      email_template = Template::EmailTemplate.find_by(name: "user_confirmation_instructions")
      attrs = {
        booking_portal_client_id: booking_portal_client_id,
        subject: email_template.parsed_subject(self),
        body: ERB.new(self.booking_portal_client.email_header).result( binding) + email_template.parsed_content(self) + ERB.new(self.booking_portal_client.email_footer).result( binding ),
        cc: [ booking_portal_client.notification_email ],
        recipients: [ self ],
        triggered_by_id: id,
        triggered_by_type: self.class.to_s
      }
      attrs[:to] = [ unconfirmed_email ] if pending_reconfirmation?
      email = Email.create!(attrs)
      email.sent! if email_template.is_active?
    end
  end

  def is_payment_done?
    receipts.where('$or' => [{ status: { '$in': %w(success clearance_pending) } }, { payment_mode: {'$ne': 'online'}, status: {'$in': %w(pending clearance_pending success)} }]).present?
  end

  def is_booking_done?
    booking_details.where(status: {"$in": BookingDetail::BOOKING_STAGES}).present?
  end

  def send_payment_link
    url = Rails.application.routes.url_helpers
    hold_booking_detail = self.booking_details.where(status: 'hold').first
    if hold_booking_detail.present? && hold_booking_detail.search
      self.payment_link = url.checkout_user_search_path(hold_booking_detail.search)
    else
      self.payment_link = url.dashboard_url("remote-state": url.new_buyer_receipt_path, user_email: email, user_token: authentication_token)
    end
    #
    # Send email with payment link
    email_template = ::Template::EmailTemplate.find_by(name: "payment_link")
    email = Email.create!({
      booking_portal_client_id: booking_portal_client_id,
      body: ERB.new(self.booking_portal_client.email_header).result( binding) + email_template.parsed_content(self) + ERB.new(self.booking_portal_client.email_footer).result( binding ),
      subject: email_template.parsed_subject(self),
      recipients: [ self ],
      triggered_by_id: id,
      triggered_by_type: self.class.to_s
    })
    email.sent!
    # Send sms with link for payment
    sms_template = Template::SmsTemplate.find_by(name: "payment_link")
    sms_body = sms_template.parsed_content(self)
    Sms.create!({
      booking_portal_client_id: booking_portal_client,
      body: sms_body,
      recipient: self,
      triggered_by_id: id,
      triggered_by_type: self.class.to_s
    }) unless sms_body.blank?
  end

  def update_selldo_credentials(oauth_data)
    self.selldo_access_token = oauth_data.credentials.token if oauth_data
  end

  def push_srd_to_selldo
    _selldo_api_key = Client.selldo_api_clients.dig(:website, :api_key)

    if self.manager_id.present? && _selldo_api_key.present?
      campaign_resp = if self.manager_role?('channel_partner')
        { srd: self.booking_portal_client.selldo_cp_srd, sub_source: self.manager_name }
      elsif self.manager.role.in?((ADMIN_ROLES - %w(channel_partner)))
        { srd: self.booking_portal_client.selldo_default_srd, sub_source: self.manager_name }
      end

      SelldoLeadUpdater.perform_async(self.id, { action: 'add_campaign_response', api_key: _selldo_api_key }.merge(campaign_resp))
    end
  end

  # Class Methods
  class << self

    def build_criteria(params = {})
      criteria = super(params)
      criteria = criteria.where(role: { "$ne": 'superadmin' }) unless criteria.selector.has_key?('role')
      criteria
    end

    def buyer_roles(current_client = nil)
      if current_client.present? && current_client.enable_company_users?
        BUYER_ROLES
      else
        ['user']
      end
    end

    def available_confirmation_statuses
      [
        { id: 'confirmed', text: 'Confirmed' },
        { id: 'not_confirmed', text: 'Not Confirmed' }
      ]
    end

    def available_roles(current_client)
      roles = ADMIN_ROLES + BUYER_ROLES
      roles -= CHANNEL_PARTNER_USERS unless current_client.try(:enable_channel_partners?)
      roles -= COMPANY_USERS unless current_client.try(:enable_company_users?)
      roles
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
        any_of({ phone: login }, email: login).first
      else
        super
      end
    end

    def find_record(login)
      where("function() {return this.phone == '#{login}' || this.email == '#{login}'}")
    end

    def user_based_scope(user, _params = {})
      custom_scope = {}
      if user.role?('channel_partner')
        custom_scope = { role: {"$in": User.buyer_roles(user.booking_portal_client)} }
        custom_scope[:'$or'] = [{manager_id: user.id}, {manager_id: nil, referenced_manager_ids: user.id, iris_confirmation: false}]
      elsif user.role?('crm')
        custom_scope = { role: { "$in": User.buyer_roles(user.booking_portal_client) + %w(channel_partner) } }
      elsif user.role?('sales_admin')
        custom_scope = { "$or": [{ role: { "$in": User.buyer_roles(user.booking_portal_client) } }, { role: 'sales' }, { role: 'channel_partner' }] }
      elsif user.role?('sales')
        custom_scope = { role: { "$in": User.buyer_roles(user.booking_portal_client) } }
      elsif user.role?('cp_admin')
        custom_scope = { "$or": [{ role: { "$in": User.buyer_roles(user.booking_portal_client) } }, { role: 'cp' }, { role: 'channel_partner' }] }
      elsif user.role?('cp')
        custom_scope = { "$or": [{ role: 'user', referenced_manager_ids: { "$in": User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id) } }, { role: 'channel_partner', manager_id: user.id }] }
      elsif user.role?('admin')
        custom_scope = { role: { "$ne": 'superadmin' } }
      end
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
          user.booking_portal_client ||= (client || current_client)
          user.confirmed_at = Time.now unless user.confirmed?
          user.role = role
        end
        if user.save
          user.update_selldo_credentials(oauth_data)
          user
        end
      else
        User.where(matcher).first
      end
    end
  end

  protected

  def send_confirmation_notification?
    confirmation_required? && !@skip_confirmation_notification && (self.email.present? || self.phone.present?)
  end

  private

  def manager_change_reason_present?
    if persisted? && manager_id_changed? && manager_change_reason.blank?
      errors.add :manager_change_reason, 'is required'
    end
  end
end
