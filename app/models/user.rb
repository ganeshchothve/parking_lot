class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable #:registerable Disbaling registration because we always create user after set up sell.do

  ## Database authenticatable
  field :name, type: String, default: ""
  field :email, type: String, default: ""
  field :phone, type: String, default: ""
  field :lead_id, type: String


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
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  has_many :receipts
  has_many :project_units
  has_many :user_requests

  validates :name, :phone, :lead_id, presence: true
  validates :lead_id, uniqueness: true
  validates :email, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, phone: true # TODO: we can remove phone validation, as the validation happens in sell.do

  def email_required?
    false
  end

  # use this instead of email_changed? for rails >= 5.1
  def will_save_change_to_email?
    false
  end

  def unattached_blocking_receipt
    return self.receipts.where(project_unit_id: nil, status: 'success', payment_type: 'blocking', total_amount: ProjectUnit.blocking_amount).first
  end

  def total_amount_paid
    self.receipts.where(status: 'success').sum(:total_amount)
  end

  def total_balance_pending
    self.project_units.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).sum{|x| x.pending_balance}
  end

  def total_unattached_balance
    self.receipts.where(status: 'success', project_unit_id: nil).sum(:total_amount)
  end
end
