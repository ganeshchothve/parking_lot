require 'autoinc'
class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  include ReceiptStateMachine
  include SyncDetails
  extend FilterByCriteria

  OFFLINE_PAYMENT_MODE = %w[cheque rtgs imps card_swipe neft]

  field :receipt_id, type: String
  field :order_id, type: String
  field :payment_mode, type: String, default: 'online'
  field :issued_date, type: Date # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :tracking_id, type: String # online transaction reference from gateway or transaction id after the cheque is processed
  field :total_amount, type: Float, default: 0 # Total amount
  field :status, type: String, default: 'pending' # pending, success, failed, clearance_pending,cancelled
  field :status_message, type: String # pending, success, failed, clearance_pending
  field :payment_gateway, type: String
  field :processed_on, type: Date
  field :comments, type: String
  field :gateway_response, type: Hash
  field :erp_id, type: String, default: ''

  belongs_to :user
  belongs_to :booking_detail, optional: true
  belongs_to :creator, class_name: 'User'
  belongs_to :account, foreign_key: 'account_number', optional: true
  # remove optional: true when implementing.
  has_many :assets, as: :assetable
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :sync_logs, as: :resource

  scope :filter_by_status, ->(_status) { where(status: _status) }
  scope :filter_by_receipt_id, ->(_receipt_id) { where(receipt_id: /#{_receipt_id}/i) }
  scope :filter_by_user_id, ->(_user_id) { where(user_id: _user_id) }

  scope :filter_by_payment_mode, ->(_payment_mode) { where(payment_mode: _payment_mode) }
  scope :filter_by_issued_date, ->(date) { start_date, end_date = date.split(' - '); where(issued_date: start_date..end_date) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: start_date..end_date) }
  scope :filter_by_processed_on, ->(date) { start_date, end_date = date.split(' - '); where(processed_on: start_date..end_date) }

  validates :issuing_bank, :issuing_bank_branch, format: { without: /[^a-z\s]/i, message: 'can contain only alphabets and spaces' }, unless: proc { |receipt| receipt.payment_mode == 'online' }
  validates :payment_identifier, format: { without: /[^a-z0-9\s]/i, message: 'can contain only alphabets, numbers and spaces' }, unless: proc { |receipt| receipt.payment_mode == 'online' }
  validates :total_amount, :status, :payment_mode, :user_id, presence: true
  validates :payment_identifier, presence: true, if: proc { |receipt| receipt.payment_mode == 'online' ? receipt.status == 'success' : true }
  validates :status, inclusion: { in: proc { Receipt.aasm.states.collect(&:name).collect(&:to_s) } }
  validates :payment_mode, inclusion: { in: proc { Receipt.available_payment_modes.collect { |x| x[:id] } } }
  validate :validate_total_amount
  validates :issued_date, :issuing_bank, :issuing_bank_branch, presence: true, if: proc { |receipt| receipt.payment_mode != 'online' }
  validates :processed_on, presence: true, if: proc { |receipt| %i[success clearance_pending available_for_refund].include?(receipt.status) }
  validates :payment_gateway, presence: true, if: proc { |receipt| receipt.payment_mode == 'online' }
  validates :payment_gateway, inclusion: { in: PaymentGatewayService::Default.allowed_payment_gateways }, allow_blank: true
  validates :tracking_id, presence: true, if: proc { |receipt| receipt.status == 'success' && receipt.payment_mode != 'online' }
  validates :comments, presence: true, if: proc { |receipt| receipt.status == 'failed' && receipt.payment_mode != 'online' }
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :tracking_id_processed_on_only_on_success, if: proc { |record| record.status != 'cancelled' }
  validate :processed_on_greater_than_issued_date, :first_booking_amount_limit
  validate :issued_date_when_offline_payment, if: proc { |record| %w[online cheque].exclude?(record.payment_mode) && issued_date.present? }

  increments :order_id, auto: false

  delegate :project_unit, to: :booking_detail, prefix: false, allow_nil: true

  enable_audit(
    associated_with: ['user'],
    indexed_fields: %i[receipt_id order_id payment_mode tracking_id creator_id],
    audit_fields: %i[payment_mode tracking_id total_amount issued_date issuing_bank issuing_bank_branch payment_identifier status status_message booking_detail_id]
  )

  def self.available_payment_modes
    [
      { id: 'online', text: 'Online' },
      { id: 'cheque', text: 'Cheque' },
      { id: 'rtgs', text: 'RTGS' },
      { id: 'imps', text: 'IMPS' },
      { id: 'card_swipe', text: 'Card Swipe' },
      { id: 'neft', text: 'NEFT' }
    ]
  end

  def self.available_sort_options
    [
      { id: 'created_at.asc', text: 'Created - Oldest First' },
      { id: 'created_at.desc', text: 'Created - Newest First' },
      { id: 'issued_date.asc', text: 'Issued Date - Oldest First' },
      { id: 'issued_date.desc', text: 'Issued Date- Newest First' },
      { id: 'processed_on.asc', text: 'Proccessed On - Oldest First' },
      { id: 'processed_on.desc', text: 'Proccessed On - Newest First' }
    ]
  end

  def primary_user_kyc
    if booking_detail.present? && booking_detail.user_id == user_id
      booking_detail.primary_user_kyc
    else
      UserKyc.where(user_id: user_id).asc(:created_at).first
    end
  end

  def payment_gateway_service
    if payment_mode == 'online'
      eval("PaymentGatewayService::#{payment_gateway}").new(self)
    end
  end

  def issued_date_when_offline_payment
    errors.add(:issued_date, 'should be less than or equal to the current date') unless issued_date <= Time.now
  end

  def blocking_payment?
    !direct_payment? && booking_detail.receipts.in(status: %w[success clearance_pending]).count.zero?
  end

  def generate_receipt_id
    if status == 'success'
      assign!(:order_id) if order_id.blank?
      if booking_detail_id.present?
        "#{user.booking_portal_client.name[0..1].upcase}-#{booking_detail.name[0..1].upcase}-#{order_id}"
      else
        "#{user.booking_portal_client.name[0..1].upcase}-#{order_id}"
      end
    elsif receipt_id.blank?
      "#{user.booking_portal_client.name[0..1].upcase}-TMP-#{SecureRandom.hex(4)}"
    else
      receipt_id
    end
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    if params[:user_id].blank? && !user.buyer?
      if user.role?('channel_partner')
        custom_scope = { user_id: { "$in": User.where(referenced_manager_ids: user.id).distinct(:id) } }
      elsif user.role?('cp_admin')
        custom_scope = { user_id: { "$in": User.where(role: 'user').nin(manager_id: [nil, '']).distinct(:id) } }
      elsif user.role?('cp')
        channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
        custom_scope = { user_id: { "$in": User.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
      end
    end

    custom_scope = { user_id: params[:user_id] } if params[:user_id].present?
    custom_scope = { user_id: user.id } if user.buyer?

    custom_scope[:booking_detail_id] = params[:booking_detail_id] if params[:booking_detail_id].present?
    custom_scope
  end

  #
  # Initial Payment should be greater than blocking amount.
  #
  #
  def first_booking_amount_limit
    if booking_detail.try(:hold?)
      if total_amount < project_unit.blocking_amount
        errors.add(:total_amount, "should be greater than blocking amount(#{project_unit.blocking_amount})")
      end
    end
  end

  def sync(erp_model, sync_log)
    Api::ReceiptDetailsSync.new(erp_model, self, sync_log).execute if user.buyer? && user.erp_id.present?
  end

  def direct_payment?
    booking_detail_id.blank?
  end

  private

  def validate_total_amount
    if total_amount <= 0
      errors.add :total_amount, 'cannot be less than or equal to 0'
    else
      blocking_amount = user.booking_portal_client.blocking_amount
      blocking_amount = project_unit.blocking_amount if booking_detail_id.present?
      if (direct_payment? || blocking_payment?) && total_amount < blocking_amount && new_record? && !booking_detail.swapping?
        errors.add :total_amount, "cannot be less than blocking amount #{user.booking_portal_client.blocking_amount}"
      end
    end
  end

  def tracking_id_processed_on_only_on_success
    if status_changed? && status != 'success' && payment_mode != 'online'
      errors.add :tracking_id, 'cannot be set unless the status is marked as success' if tracking_id_changed? && tracking_id.present?
      errors.add :processed_on, 'cannot be set unless the status is marked as success' if processed_on_changed? && processed_on.present?
    end
  end

  def processed_on_greater_than_issued_date
    if processed_on.present? && issued_date.present?
      if processed_on < issued_date
        errors.add :processed_on, 'cannot be older than the Issued Date'
      elsif processed_on > Time.now.to_date
        errors.add :processed_on, 'cannot be in the future'
      end
    end
  end

  # Payment can be done only when the project unit is blocked,booked_tentative or booked_confirmed or it is under_negotiation with approved scheme.
  def allowed_stages
    ProjectUnit.booking_stages.exclude?(project_unit.status) && ((project_unit.status == 'under_negotiation') && ['approved'].exclude?(project_unit.scheme.status))
  end
end
