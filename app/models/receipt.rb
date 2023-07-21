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
  extend DocumentsConcern

  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  OFFLINE_PAYMENT_MODE = %w[cheque rtgs imps card_swipe neft]
  PAYMENT_TYPES = %w[agreement stamp_duty token]
  PAYMENT_MODES = %w[cheque rtgs imps card_swipe neft online]
  STATUSES = %w[pending clearance_pending success cancellation_requested cancelling cancelled cancellation_rejected failed available_for_refund refunded]
  # Add different types of documents which are uploaded on receipt
  DOCUMENT_TYPES = []

  # Mandatory fields - mandatory
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :total_amount, type: Float # Total amount
  field :status, type: String, default: 'pending' # pending, success, failed, clearance_pending,cancelled
  field :issued_date, type: Date # Date when cheque / DD etc are issued
  #Auto generated fields and mandatory
  field :receipt_id, type: String
  #Payment gateway related fields - non mandatory
  field :order_id, type: String
  field :tracking_id, type: String # online transaction reference from gateway or transaction id after the cheque is processed
  field :payment_gateway, type: String
  field :gateway_response, type: Hash
  field :transfer_details, type: Array, default: [] #stores tranfer details for razorpay payment
  field :status_message, type: String # pending, success, failed, clearance_pending
  #Offline payment fields - non mandatory
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :processed_on, type: Date

  #Other fields - non mandatory
  field :payment_mode, type: String, default: 'online'
  field :payment_type, type: String, default: 'agreement' # possible values are :agreement and :stamp_duty
  field :comments, type: String
  field :erp_id, type: String, default: ''
  field :state_machine_errors, type: Array, default: []

  attr_accessor :swap_request_initiated

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :user
  belongs_to :lead
  belongs_to :project
  belongs_to :booking_detail, optional: true
  belongs_to :creator, class_name: 'User'
  belongs_to :account, foreign_key: 'account_number', optional: true
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :channel_partner, optional: true
  belongs_to :cp_manager, class_name: 'User', optional: true
  belongs_to :cp_admin, class_name: 'User', optional: true
  # remove optional: true when implementing.
  has_many :assets, as: :assetable
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :user_requests, as: :requestable
  has_one :user_kyc
  has_one :coupon

  scope :filter_by_status, ->(status) { all.in(status: (status.is_a?(Array) ? status : [status])) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in" => project_ids}) : all }
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}
  scope :filter_by_receipt_id, ->(_receipt_id) { where(receipt_id: /#{_receipt_id}/i) }
  scope :filter_by_token_number, ->(_token_number) { where(token_number: _token_number) }
  scope :filter_by_user_id, ->(_user_id) { where(user_id: _user_id) }
  scope :filter_by_payment_mode, ->(_payment_mode) { where(payment_mode: _payment_mode) }
  scope :filter_by_payment_type, ->(_payment_type) { where(payment_type: _payment_type) }
  scope :filter_by_issued_date, ->(date) { start_date, end_date = date.split(' - '); where(issued_date: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_processed_on, ->(date) { start_date, end_date = date.split(' - '); where(processed_on: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where(receipt_id: regex ) }
  scope :direct_payments, ->{ where(booking_detail_id: nil )}
  scope :filter_by_booking_detail_id, ->(_booking_detail_id) do
    _booking_detail_id = _booking_detail_id == '' ? { '$in' => ['', nil] } : _booking_detail_id
    where(booking_detail_id: _booking_detail_id)
  end
  scope :filter_by_booking_detail_id_presence, ->(flag) { flag.to_s == 'true' ? where(booking_detail_id: { '$nin': [ '', nil ] } ) : where(booking_detail_id: { '$in': [ '', nil ] } ) }
  scope :filter_by_manager_id, ->(manager_id){ where(manager_id: manager_id) }
  scope :filter_by_cp_manager_id, ->(cp_manager_id){ where(cp_manager_id: cp_manager_id) }
  scope :filter_by_booking_portal_client_id, ->(booking_portal_client_id) { where(booking_portal_client_id: booking_portal_client_id) }

  scope :filter_by_reference_id, ->(reference_id) {
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
  }

  scope :filter_by_cp_reference_id, ->(cp_reference_id) {
      if cp_reference_id.present?
        third_party_references = []
        cp_reference_id.each do |key, value|
          next if (key.blank? || value.blank?)
          crm_id = (BSON.ObjectId(key) rescue "")
          third_party_references << {"third_party_references.crm_id": crm_id, "third_party_references.reference_id": value}
        end
        if third_party_references.present?
          channel_partner_users = User.filter_by_role("channel_partner").where("$or": third_party_references)
          leads = Lead.where(manager_id: {"$in": channel_partner_users.pluck(:id)}) if channel_partner_users.present?
          if leads.present?
            where(lead_id: {"$in": leads.pluck(:id)})
          else
            Receipt.none
          end
        end
      end
  }

  scope :filter_by_cp_code, ->(cp_code) {
      channel_partner = ChannelPartner.where(cp_code: cp_code)
      associated_users = User.filter_by_role("channel_partner").in(id: channel_partner.pluck(:associated_user_id)) if channel_partner.present?
      leads = Lead.in(manager_id: associated_users.pluck(:id)) if associated_users.present?
      if channel_partner.present? && leads.present?
        where(lead_id: {"$in": leads.pluck(:id)})
      else
        Receipt.none #for get Mongoid::Criteria object with no records if channel partner not found
      end
  }


  #validations for fields without default value
  validates :total_amount, presence: true
  validate :validate_total_amount, if: proc { |receipt| receipt.total_amount.present? }
  validates :issued_date, :issuing_bank, :issuing_bank_branch, presence: true, if: proc { |receipt| receipt.payment_mode != 'online' }
  validates :payment_identifier, presence: true , if: proc { |receipt| receipt.payment_mode == 'online' ? receipt.status == 'success' : true }
  #validations for fields with default value
  validates :status, :payment_mode, :payment_type, presence: true
  validates :status, inclusion: { in: proc { Receipt.aasm.states.collect(&:name).collect(&:to_s) } }
  validates :payment_mode, inclusion: { in: I18n.t("mongoid.attributes.receipt/payment_mode").keys.map(&:to_s) }, allow_blank: true
  validates :payment_type, inclusion: { in: Receipt::PAYMENT_TYPES }, if: proc { |receipt| receipt.payment_type.present? }
  # non mandatory fields
  #validates :issuing_bank, :issuing_bank_branch, name: true, allow_blank: true
  # validates :payment_identifier, length: { in: 3..25 }, format: { without: /[^A-Za-z0-9_-]/, message: "can contain only alpha-numaric with '_' and '-' "}, if: proc { |receipt| receipt.offline? && receipt.payment_identifier.present? }
  # validates :processed_on, presence: true, if: proc { |receipt| %i[success clearance_pending available_for_refund].include?(receipt.status) }
  # validates :payment_gateway, presence: true, if: proc { |receipt| receipt.payment_mode == 'online' }
  validates :payment_gateway, inclusion: { in: PaymentGatewayService::Default.allowed_payment_gateways }, allow_blank: true, if: proc { |receipt| receipt.payment_mode == 'online' }
  # validates :tracking_id, length: { in: 5..15 }, presence: true, if: proc { |receipt| receipt.status == 'success' && receipt.payment_mode != 'online' }
  # validates :comments, presence: true, if: proc { |receipt| receipt.status == 'failed' && receipt.payment_mode != 'online' }
  validates :erp_id, uniqueness: {scope: :project_id, message: '^Receipt with Erp Id: %{value} already exists'}, allow_blank: true
  # validate :tracking_id_processed_on_only_on_success, if: proc { |record| record.status != 'cancelled' }
  validate :processed_on_greater_than_issued_date
  # validate :issued_date_when_offline_payment, if: proc { |record| %w[online cheque].exclude?(record.payment_mode) && issued_date.present? }
  validates :user_kyc, copy_errors_from_child: true

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

  def name_in_error
    "#{receipt_id}"
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

  def primary_user_kyc
    if booking_detail.present? && booking_detail.user_id == user_id
      booking_detail.primary_user_kyc
    else
      UserKyc.where(booking_portal_client_id: self.booking_portal_client_id, user_id: user_id).asc(:created_at).first
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
    project_ids = (params[:current_project_id].present? ? [params[:current_project_id]] : user.project_ids)
    if params[:lead_id].blank? && !user.buyer?
      if user.role?('channel_partner')
        custom_scope = { manager_id: user.id, channel_partner_id: user.channel_partner_id }
      elsif user.role?('cp_owner')
        custom_scope = { channel_partner_id: user.channel_partner_id }
      elsif user.role?('cp_admin')
        #cp_ids = User.where(role: 'cp', manager_id: user.id).distinct(:id)
        #channel_partner_ids = User.where(role: 'channel_partner', manager_id: {"$in": cp_ids}).distinct(:id)
        #custom_scope = { manager_id: { "$in": channel_partner_ids } }
        custom_scope = {cp_admin_id: user.id}
      elsif user.role?('cp')
        #channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
        #custom_scope = { manager_id: { "$in": channel_partner_ids } }
        custom_scope = {cp_manager_id: user.id}
      elsif user.role?(:admin)
        custom_scope = {  }
      elsif user.role.in?(%w(sales gre))
        custom_scope = { }
      elsif user.role.in?(%w(superadmin))
        custom_scope = {  }
      end
    end

    custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
    if user.buyer?
      if params[:current_project_id].present?
        custom_scope = { user_id: user.id, project_id: params[:current_project_id] }
      else
        custom_scope = { user_id: user.id }
      end
    end

    custom_scope[:booking_detail_id] = params[:booking_detail_id] if params[:booking_detail_id].present?

    if !user.role.in?(User::ALL_PROJECT_ACCESS) || params[:current_project_id].present?
      custom_scope.merge!({project_id: { "$in": project_ids } })
    end
    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
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
      blocking_amount = token_type.token_amount if direct_payment? && token_type.present?
      blocking_amount = project.blocking_amount if blocking_amount.blank?
      blocking_amount = user.booking_portal_client.blocking_amount if blocking_amount.blank?
      blocking_amount = project_unit.blocking_amount if booking_detail_id.present? && project_unit.present?

      if (direct_payment? || blocking_payment?) && total_amount < blocking_amount && !booking_detail.try(:swapping?)
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
