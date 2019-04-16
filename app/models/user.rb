require "active_model_otp"
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ActiveModel::OneTimePassword
  include InsertionStringMethods
  include ApplicationHelper

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :confirmable, authentication_keys: [:login] #:registerable Disbaling registration because we always create user after set up sell.do

  ## Database authenticatable
  field :first_name, type: String, default: ""
  field :last_name, type: String, default: ""
  field :email, type: String, default: ""
  field :phone, type: String, default: ""
  field :lead_id, type: String
  field :role, type: String, default: "user"
  field :allowed_bookings, type: Integer
  field :manager_id, type: BSON::ObjectId
  field :manager_change_reason, type: String
  field :referenced_manager_ids, type: Array, default: []
  field :rera_id, type: String
  field :mixpanel_id, type: String
  field :time_zone, type: String, default: "Mumbai"

  field :encrypted_password, type: String, default: ""

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

  ## Token Authenticatable
  acts_as_token_authenticatable
  field :authentication_token

  field :is_active, type: Boolean, default: true

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  # field for active_model_otp
  field :otp_secret_key
  field :referral_code, type: String

  def self.otp_length
    6
  end

  has_one_time_password length: User.otp_length
  default_scope -> {desc(:created_at)}

  include OtpLoginHelperMethods

  enable_audit({
    indexed_fields: [:first_name, :last_name],
    audit_fields: [:status, :lead_id, :role, :allowed_bookings, :manager_id, :referenced_manager_ids, :rera_id, :mixpanel_id, :email, :phone],
    reference_ids_without_associations: [
      {field: 'referenced_manager_ids', klass: 'ChannelPartner'},
    ]
  })

  # key to handle both phone or email as a login
  attr_accessor :login, :login_otp

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :users
  belongs_to :referred_by, class_name: 'User', optional: true
  has_many :receipts
  has_many :project_units
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :searches
  has_many :received_smses, class_name: "Sms", inverse_of: :recipient
  has_and_belongs_to_many :received_emails, class_name: "Email", inverse_of: :recipients
  has_and_belongs_to_many :cced_emails, class_name: "Email", inverse_of: :cc_recipients

  has_many :notes, as: :notable
  has_many :smses, as: :triggered_by, class_name: "Sms"
  has_many :emails, as: :triggered_by, class_name: "Email"
  has_many :referrals, class_name: 'User', foreign_key: :referred_by_id
  embeds_many :portal_stages
  accepts_nested_attributes_for :portal_stages, reject_if: :all_blank

  validates :first_name, :role, presence: true
  validates :phone, uniqueness: true, phone: { possible: true, types: [:voip, :personal_number, :fixed_or_mobile]}, if: Proc.new{|user| user.email.blank? }
  validates :email, uniqueness: true, if: Proc.new{|user| user.phone.blank? }
  validates :rera_id, presence: true, if: Proc.new{ |user| user.role?('channel_partner') }
  validates :rera_id, uniqueness: true, allow_blank: true
  validates :role, inclusion: {in: Proc.new{ |user| User.available_roles(user.booking_portal_client).collect{|x| x[:id]} } }
  validates :lead_id, uniqueness: true, presence: true, if: Proc.new{ |user| user.buyer? }, allow_blank: true
  validate :manager_change_reason_present?

  def unattached_blocking_receipt blocking_amount=nil
    blocking_amount ||= current_client.blocking_amount
    return Receipt.where(user_id: self.id).in(status: ['success', 'clearance_pending']).where(project_unit_id: nil).where(total_amount: {"$gte": blocking_amount}).first
  end

  def total_amount_paid
    self.receipts.where(status: 'success').sum(:total_amount)
  end

  def portal_stage
    user.portal_stages.desc(:created_at).first
  end

  def total_balance_pending
    self.project_units.in(status: ProjectUnit.booking_stages).sum{|x| x.pending_balance}
  end

  def total_unattached_balance
    self.receipts.in(status: ['success', 'clearance_pending']).where(project_unit_id: nil).sum(:total_amount)
  end

  def kyc_ready?
    self.user_kyc_ids.present?
  end

  def buyer?
    if current_client.enable_company_users?
      ['user', 'management_user', 'employee_user'].include?(self.role)
    else
      self.role == 'user'
    end
  end

  def self.buyer_roles(current_client=nil)
    if current_client.present? && current_client.enable_company_users?
      ['user', 'management_user', 'employee_user']
    else
      ['user']
    end
  end

  def self.available_confirmation_statuses
    [
      {id: "confirmed", text: "Confirmed"},
      {id: "not_confirmed", text: "Not Confirmed"}
    ]
  end

  def self.available_roles(current_client)
    roles = [
      {id: 'superadmin', text: 'Superadmin'},
      {id: 'admin', text: 'Administrator'},
      {id: 'crm', text: 'CRM User'},
      {id: 'sales_admin', text: 'Sales Head'},
      {id: 'sales', text: 'Sales User'},
      {id: 'user', text: 'Customer'},
      {id: 'gre', text: 'GRE or Pre-sales'}
    ]
    if current_client.try(:enable_channel_partners?)
      roles += [
        {id: 'cp_admin', text: 'Channel Partner Head'},
        {id: 'cp', text: 'Channel Partner Manager'},
        {id: 'channel_partner', text: 'Channel Partner'}
      ]
    end
    if current_client.present? && current_client.enable_company_users?
      roles += [
        {id: 'management_user', text: 'Management User'},
        {id: 'employee_user', text: 'Employee'}
      ]
    end
    roles
  end

  def role?(role)
    return (self.role.to_s == role.to_s)
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:role].present?
        if params[:fltrs][:role].is_a?(Array)
          selector = {role: {"$in": params[:fltrs][:role] }}
        elsif params[:fltrs][:role].is_a?(ActionController::Parameters)
          selector = {role: params[:fltrs][:role].to_unsafe_h }
        else
          selector = {role: params[:fltrs][:role] }
        end
      end
      if params[:fltrs][:lead_id].present?
        selector[:lead_id] = params[:fltrs][:lead_id]
      end
      if params[:fltrs][:confirmation].present?
        if params[:fltrs][:confirmation].eql?("not_confirmed")
          selector[:confirmed_at] = nil
        else
          selector[:confirmed_at] = {"$ne": nil}
        end
      end
    end
    selector[:role] = {"$ne": "superadmin"} if selector[:role].blank?
    or_selector = {}
    if params[:search].present?
      regex = ::Regexp.new(::Regexp.escape(params[:search]), 'i')
      or_selector = {"$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] }
    end
    self.and([selector, or_selector])
  end

  def manager
    if self.manager_id.present?
      return User.find(self.manager_id)
    else
      return nil
    end
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
    self.encrypted_password.blank?
  end

  def password_match?
    self.errors[:password] << "can't be blank" if password.blank?
    self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
    self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
    password == password_confirmation && !password.blank?
  end

  # Devise::Models:unless_confirmed` method doesn't exist in Devise 2.0.0 anymore.
  # Instead you should use `pending_any_confirmation`.
  def only_if_unconfirmed
    pending_any_confirmation {yield}
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
    host = (port == 443 ? "https://" : "http://") + host
    host = host + ((port == 443 || port == 80 || port == 0) ? "" : ":#{port}")
    url.dashboard_url(user_email: self.email, user_token: self.authentication_token, host: host)
  end

  # GENERICTODO: handle this with a way to replace urls in SMS or Email Templates
  def confirmation_url
    url = Rails.application.routes.url_helpers
    host = Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port].to_i
    host = (port == 443 ? "https://" : "http://") + host
    host = host + ((port == 443 || port == 80 || port == 0) ? "" : ":#{port}")
    url.user_confirmation_url(confirmation_token: self.confirmation_token, manager_id: self.manager_id, host: host)
  end

  def name
    str = "#{first_name} #{last_name}"
    if self.role?("channel_partner")
      cp = ChannelPartner.where(associated_user_id: self.id).first
      if cp.present? && cp.company_name.present?
        str += " (#{cp.company_name})"
      end
    end
    str
  end

  def login
    @login || self.phone || self.email
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    login = conditions.delete(:email) if login.blank? && conditions.keys.include?(:email)
    login = conditions.delete(:phone) if login.blank? && conditions.keys.include?(:phone)
    if login.blank? && warden_conditions[:confirmation_token].present?
      confirmation_token = warden_conditions.delete(:confirmation_token)
      where(confirmation_token: confirmation_token).first
    elsif login.blank? && warden_conditions[:reset_password_token].present?
      reset_password_token = warden_conditions.delete(:reset_password_token)
      where(reset_password_token: reset_password_token).first
    elsif login.present?
      any_of({phone: login}, email: login).first
    end
  end

  def active_for_authentication?
    super && is_active
  end

  def inactive_message
    is_active ? super : :is_active
  end

  def self.find_record login
    where("function() {return this.phone == '#{login}' || this.email == '#{login}'}")
  end

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  def get_search project_unit_id
    search = searches
    search = search.where(project_unit_id: project_unit_id) if project_unit_id.present?
    search = search.desc(:created_at).first
    if search.blank?
      search = Search.create(user: self)
    end
    search
  end

  def self.user_based_scope(user, params={})
    custom_scope = {}
    if user.role?('channel_partner')
      custom_scope = {referenced_manager_ids: {"$in": [user.id]}, role: {"$in": User.buyer_roles(user.booking_portal_client)} }
    elsif user.role?('crm')
      custom_scope = {role: {"$in": User.buyer_roles(user.booking_portal_client)}}
    elsif user.role?('sales_admin')
      custom_scope = {"$or": [{role: {"$in": User.buyer_roles(user.booking_portal_client)}}, {role: "sales"}, {role: "channel_partner"}]}
    elsif user.role?('sales')
      custom_scope = {role: {"$in": User.buyer_roles(user.booking_portal_client)}}
    elsif user.role?('cp_admin')
      custom_scope = {"$or": [{role: {"$in": User.buyer_roles(user.booking_portal_client)}}, {role: "cp"}, {role: "channel_partner"}]}
    elsif user.role?('cp')
      custom_scope = {"$or": [{role: 'user', referenced_manager_ids: {"$in": User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)}}, {role: "channel_partner", manager_id: user.id}]}
    elsif user.role?("admin")
      custom_scope = {role: {"$ne": "superadmin"}}
    end
    custom_scope
  end

  def unused_user_kyc_ids project_unit_id
    if self.booking_portal_client.allow_multiple_bookings_per_user_kyc?
      user_kyc_ids = self.user_kycs.collect{|x| x.id}
    else
      user_kyc_ids = self.user_kycs.collect{|x| x.id}
      self.project_units.ne(id: project_unit_id).each do |x|
        user_kyc_ids = user_kyc_ids - [x.primary_user_kyc_id] - x.user_kyc_ids
      end
    end
    user_kyc_ids
  end

  private
  def manager_change_reason_present?
    if self.persisted? && self.manager_id_changed? && self.manager_change_reason.blank?
      self.errors.add :manager_change_reason, "is required"
    end
  end
end
