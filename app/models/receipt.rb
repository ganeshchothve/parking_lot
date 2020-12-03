require 'autoinc'
class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include Mongoid::Autoinc
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  include ReceiptStateMachine
  # include SyncDetails
  include TimeSlotGeneration
  include CrmIntegration
  extend FilterByCriteria

  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  OFFLINE_PAYMENT_MODE = %w[cheque rtgs imps card_swipe neft]
  PAYMENT_TYPES = %w[agreement stamp_duty token]
  PAYMENT_MODES = %w[cheque rtgs imps card_swipe neft online]
  STATUSES = %w[pending clearance_pending success cancellation_requested cancelling cancelled cancellation_rejected failed available_for_refund refunded]
  # Add different types of documents which are uploaded on receipt
  DOCUMENT_TYPES = []

  field :receipt_id, type: String
  field :order_id, type: String
  field :payment_mode, type: String, default: 'online'
  field :issued_date, type: Date # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :tracking_id, type: String # online transaction reference from gateway or transaction id after the cheque is processed
  field :total_amount, type: Float # Total amount
  field :status, type: String, default: 'pending' # pending, success, failed, clearance_pending,cancelled
  field :status_message, type: String # pending, success, failed, clearance_pending
  field :payment_gateway, type: String
  field :processed_on, type: Date
  field :comments, type: String
  field :gateway_response, type: Hash
  field :erp_id, type: String, default: ''
  field :payment_type, type: String, default: 'agreement' # possible values are :agreement and :stamp_duty
  field :transfer_details, type: Array, default: [] #stores tranfer details for razorpay payment
  field :state_machine_errors, type: Array, default: []

  attr_accessor :swap_request_initiated

  belongs_to :user
  belongs_to :lead
  belongs_to :project
  belongs_to :booking_detail, optional: true
  belongs_to :creator, class_name: 'User'
  belongs_to :account, foreign_key: 'account_number', optional: true
  belongs_to :invoice, optional: true  # For CP incentive, attach a receipt to invoice for storing cheque details.
  # remove optional: true when implementing.
  has_many :assets, as: :assetable
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :user_requests, as: :requestable
  has_one :user_kyc

  scope :filter_by_status, ->(_status) { where(status: { '$in' => _status }) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}
  scope :filter_by_receipt_id, ->(_receipt_id) { where(receipt_id: /#{_receipt_id}/i) }
  scope :filter_by_token_number, ->(_token_number) { where(token_number: _token_number) }
  scope :filter_by_user_id, ->(_user_id) { where(user_id: _user_id) }
  scope :filter_by_payment_mode, ->(_payment_mode) { where(payment_mode: _payment_mode) }
  scope :filter_by_issued_date, ->(date) { start_date, end_date = date.split(' - '); where(issued_date: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_processed_on, ->(date) { start_date, end_date = date.split(' - '); where(processed_on: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_booking_detail_id, ->(_booking_detail_id) do
    _booking_detail_id = _booking_detail_id == '' ? { '$in' => ['', nil] } : _booking_detail_id
    where(booking_detail_id: _booking_detail_id)
  end
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where(receipt_id: regex ) }

  scope :direct_payments, ->{ where(booking_detail_id: nil )}

  validates :payment_type, presence: true
  validates :payment_type, inclusion: { in: Receipt::PAYMENT_TYPES }, if: proc { |receipt| receipt.payment_type.present? }
  validates :issuing_bank, name: true, if: proc { |receipt| receipt.issuing_bank.present? }
  validates :issuing_bank_branch, name: true, if: proc { |receipt| receipt.issuing_bank_branch.present? }
  # validates :payment_identifier, length: { in: 3..25 }, format: { without: /[^A-Za-z0-9_-]/, message: "can contain only alpha-numaric with '_' and '-' "}, if: proc { |receipt| receipt.offline? && receipt.payment_identifier.present? }
  validates :total_amount, :status, :payment_mode, :user_id, presence: true
  validates :payment_identifier, presence: true, if: proc { |receipt| receipt.payment_mode == 'online' ? receipt.status == 'success' : true }
  validates :status, inclusion: { in: proc { Receipt.aasm.states.collect(&:name).collect(&:to_s) } }
  validates :payment_mode, inclusion: { in: proc { Receipt.available_payment_modes.collect { |x| x[:id] } } }
  validate :validate_total_amount, if: proc { |receipt| receipt.total_amount.present? }
  validates :issued_date, :issuing_bank, :issuing_bank_branch, presence: true, if: proc { |receipt| receipt.payment_mode != 'online' }
  validates :processed_on, presence: true, if: proc { |receipt| %i[success clearance_pending available_for_refund].include?(receipt.status) }
  validates :payment_gateway, presence: true, if: proc { |receipt| receipt.payment_mode == 'online' }
  validates :payment_gateway, inclusion: { in: PaymentGatewayService::Default.allowed_payment_gateways }, allow_blank: true, if: proc { |receipt| receipt.payment_mode == 'online' }
  # validates :tracking_id, length: { in: 5..15 }, presence: true, if: proc { |receipt| receipt.status == 'success' && receipt.payment_mode != 'online' }
  validates :comments, presence: true, if: proc { |receipt| receipt.status == 'failed' && receipt.payment_mode != 'online' }
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :tracking_id_processed_on_only_on_success, if: proc { |record| record.status != 'cancelled' }
  validate :processed_on_greater_than_issued_date
  validate :issued_date_when_offline_payment, if: proc { |record| %w[online cheque].exclude?(record.payment_mode) && issued_date.present? }
  validate :validate_user_kyc

  increments :order_id, auto: false

  delegate :project_unit, to: :booking_detail, prefix: false, allow_nil: true
  delegate :name, to: :booking_detail, prefix: true, allow_nil: true
  delegate :name, to: :project, prefix: true, allow_nil: true

  accepts_nested_attributes_for :user_kyc

  enable_audit(
    associated_with: ['user'],
    indexed_fields: %i[receipt_id order_id payment_mode tracking_id creator_id],
    audit_fields: %i[payment_mode tracking_id total_amount issued_date issuing_bank issuing_bank_branch payment_identifier status status_message booking_detail_id]
  )

  # This loop create one set of boolean method which help us to fine the payment easily.
  # This set create following methods cheque?, rtgs?, imps?, card_swipe? and neft?
  #
  # @return [Boolean]
  #
  OFFLINE_PAYMENT_MODE.each do |_payment_mode|
    define_method "#{_payment_mode}?" do
      _payment_mode.to_s == self.payment_mode.to_s
    end
  end

  def validate_user_kyc
    self.errors.add(:base, "User KYC errors - #{ user_kyc.errors.to_a.to_sentence }") if user_kyc.present? && !user_kyc.valid?
  end

  #
  # This function return true when payment has offline mode. All offline mode defined in OFFLINE_PAYMENT_MODE constant.
  #
  #
  # @return [Boolean] True for offline and false for online
  #
  def offline?
    self.class::OFFLINE_PAYMENT_MODE.include?(self.payment_mode.to_s)
  end

  #
  # This will return true when payment done by online mode.
  #
  #
  # @return [Boolean]
  #
  def online?
    payment_mode.to_s == 'online'
  end

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
    if params[:lead_id].blank? && !user.buyer?
      if user.role?('channel_partner')
        custom_scope = { lead_id: { "$in": Lead.where(referenced_manager_ids: user.id).distinct(:id) } }
      elsif user.role?('cp_admin')
        custom_scope = { lead_id: { "$in": Lead.nin(manager_id: [nil, '']).distinct(:id) } }
      elsif user.role?('cp')
        channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
        custom_scope = { lead_id: { "$in": Lead.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
      end
    end

    custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
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
    Api::ReceiptDetailsSync.new(erp_model, self, sync_log).execute
  end

  def direct_payment?
    booking_detail_id.blank?
  end

  def name
    receipt_id
  end

  alias :resource_name :name

  def self.todays_payments_count(project_id)
    filters = {
      status: %w(clearance_pending success),
      created_at: "#{DateTime.current.in_time_zone('Mumbai').beginning_of_day} - #{DateTime.current.in_time_zone('Mumbai')}",
      project_id: project_id
    }
    Receipt.build_criteria({fltrs: filters}.with_indifferent_access).count
  end

  private

  def validate_total_amount
    if (total_amount || 0) <= 0
      errors.add :total_amount, 'cannot be less than or equal to 0'
    else
      blocking_amount = user.booking_portal_client.blocking_amount
      blocking_amount = project_unit.blocking_amount if booking_detail_id.present?
      if (direct_payment? || blocking_payment?) && total_amount < blocking_amount && new_record? && !booking_detail.try(:swapping?)
        errors.add :total_amount, "cannot be less than blocking amount #{blocking_amount}"
      end
    end
  end

  def tracking_id_processed_on_only_on_success
    if self.success? && self.offline?
      errors.add :tracking_id, 'cannot be set unless the status is marked as success' if tracking_id_changed? && tracking_id.blank?
      errors.add :processed_on, 'cannot be set unless the status is marked as success' if processed_on_changed? && processed_on.blank?
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
