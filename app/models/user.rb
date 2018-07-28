require "active_model_otp"
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ActiveModel::OneTimePassword

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
  field :allowed_bookings, type: Integer, default: 3
  field :channel_partner_id, type: BSON::ObjectId
  field :referenced_channel_partner_ids, type: Array, default: []
  field :rera_id, type: String
  field :location, type: String
  field :mixpanel_id, type: String

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

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  # field for active_model_otp
  field :otp_secret_key
  def self.otp_length
    6
  end
  has_one_time_password length: User.otp_length

  # key to handle both phone or email as a login
  attr_accessor :login, :login_otp

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :users
  has_many :receipts
  has_many :project_units
  has_many :booking_details
  has_many :user_requests
  has_many :user_kycs
  has_many :searches

  validates :first_name, :last_name, :role, :allowed_bookings, presence: true
  validates :phone, uniqueness: true, phone: { possible: true, allow_blank: true, types: [:voip, :personal_number, :fixed_or_mobile]}
  validates :lead_id, uniqueness: true, allow_blank: true
  validates :email, uniqueness: true, if: Proc.new{|user| user.phone.blank? }
  validates :phone, uniqueness: true, if: Proc.new{|user| user.email.blank? }
  validates :rera_id, :location, presence: true, if: Proc.new{ |user| user.role?('channel_partner') }
  validates :rera_id, uniqueness: true, allow_blank: true
  validates :role, inclusion: {in: Proc.new{ User.available_roles.collect{|x| x[:id]} } }
  validates :lead_id, presence: true, if: Proc.new{ |user| user.buyer? }

  def unattached_blocking_receipt
    return self.receipts.in(status: ['success', 'clearance_pending']).where(project_unit_id: nil, payment_type: 'blocking').where(total_amount: {"$gte": ProjectUnit.blocking_amount}).first
  end

  def total_amount_paid
    self.receipts.where(status: 'success').sum(:total_amount)
  end

  def total_balance_pending
    self.project_units.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).sum{|x| x.pending_balance}
  end

  def total_unattached_balance
    self.receipts.in(status: ['success', 'clearance_pending']).where(project_unit_id: nil).sum(:total_amount)
  end

  def kyc_ready?
    self.user_kycs.present?
  end

  def buyer?
    ['user', 'management_user', 'employee_user'].include?(self.role)
  end

  def self.buyer_roles
    ['user', 'management_user', 'employee_user']
  end

  def self.available_roles
    [
      {id: 'superadmin', text: 'Superadmin'},
      {id: 'user', text: 'Customer'},
      {id: 'employee_user', text: 'Employee'},
      {id: 'management_user', text: 'Management User'},
      {id: 'admin', text: 'Admin'},
      {id: 'crm', text: 'CRM User'},
      {id: 'sales', text: 'Sales User'},
      {id: 'cp', text: 'Channel Partner Manager'},
      {id: 'channel_partner', text: 'Channel Partner'}
    ]
  end

  def role?(role)
    return (self.role.to_s == role.to_s)
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:role].is_a?(Array)
        selector = {role: {"$in": params[:fltrs][:role] }}
      elsif params[:fltrs][:role].is_a?(ActionController::Parameters)
        selector = {role: params[:fltrs][:role].to_unsafe_h }
      else
        selector = {role: params[:fltrs][:role] }
      end
    end
    or_selector = {}
    if params[:q].present?
      regex = ::Regexp.new(::Regexp.escape(params[:q]), 'i')
      or_selector = {"$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] }
    end
    self.where(selector).where(or_selector)
  end

  def channel_partner
    if self.channel_partner_id.present?
      return User.find(self.channel_partner_id)
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

  def dashboard_url
    url = Rails.application.routes.url_helpers
    host = Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port].to_i
    host = (port == 443 ? "https://" : "http://") + host
    host = host + ((port == 443 || port == 80 || port == 0) ? "" : ":#{port}")
    url.dashboard_url(user_email: self.email, user_token: self.authentication_token, host: host)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def login
    @login || self.phone || self.email
  end

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    login = conditions.delete(:email) if login.blank? && conditions.keys.include?(:email)
    login = conditions.delete(:phone) if login.blank? && conditions.keys.include?(:phone)
    any_of({phone: login}, email: login).first
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
    search = searches.where(project_unit_id: project_unit_id).desc(:created_at).first
    if search.blank?
      search = Search.new(user: self)
    end
    search
  end
end
