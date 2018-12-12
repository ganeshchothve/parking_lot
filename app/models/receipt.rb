require 'autoinc'
class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  include ReceiptStateMachine
  extend FilterByCriteria

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

  attr_accessor :swap_request_initiated

  belongs_to :user
  belongs_to :booking_detail, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :creator, class_name: 'User'
  has_many :assets, as: :assetable
  has_many :smses, as: :triggered_by, class_name: "Sms"

  scope :filter_by_status, ->(_status) { where(status: _status ) }
  scope :filter_by_receipt_id, ->(_receipt_id) { where(receipt_id: _receipt_id)}
  scope :filter_by_user_id, ->(_user_id){ where(user_id: _user_id) }
  scope :filter_by_project_unit_id, ->(_project_unit_id){ where(project_unit_id: _project_unit_id) }
  scope :filter_by_payment_mode, ->(_payment_mode){ where(payment_mode: _payment_mode)}
  scope :filter_by_issued_date, ->(date) { start_date, end_date = date.split(' - '); where(issued_date: start_date..end_date) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: start_date..end_date) }
  scope :filter_by_processed_on, ->(date) { start_date, end_date = date.split(' - '); where(processed_on: start_date..end_date) }

  validates :total_amount, :status, :payment_mode, :user_id, presence: true
  validates :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_mode == 'online' && receipt.status != 'pending' }
  validates :status, inclusion: {in: Proc.new{ Receipt.aasm.states.collect(&:name).collect(&:to_s) } }
  validates :payment_mode, inclusion: {in: Proc.new{ Receipt.available_payment_modes.collect{|x| x[:id]} } }
  validate :validate_total_amount
  validates :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_mode != 'online' }
  validates :payment_gateway, presence: true, if: Proc.new{|receipt| receipt.payment_mode == 'online' }
  validates :payment_gateway, inclusion: {in: PaymentGatewayService::Default.allowed_payment_gateways }, allow_blank: true
  validates :tracking_id, presence: true, if: Proc.new{|receipt| receipt.status == 'success' && receipt.payment_mode != "online"}
  validates :comments, presence: true, if: Proc.new{|receipt| receipt.status == 'failed' && receipt.payment_mode != "online"}
  validate :tracking_id_processed_on_only_on_success, if: Proc.new{|record| record.status != "cancelled" }
  validate :processed_on_greater_than_issued_date, :first_booking_amount_limit

  increments :order_id, auto: false

  enable_audit({
    associated_with: ["user"],
    indexed_fields: [:receipt_id, :order_id, :payment_mode, :tracking_id, :creator_id],
    audit_fields: [:payment_mode, :tracking_id, :total_amount, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :status, :status_message, :project_unit_id, :booking_detail_id]
  })

  def self.available_payment_modes
    [
      {id: 'online', text: 'Online'},
      {id: 'cheque', text: 'Cheque'},
      {id: 'rtgs', text: 'RTGS'},
      {id: 'imps', text: 'IMPS'},
      {id: 'neft', text: 'NEFT'}
    ]
  end

  def self.available_sort_options
    [
      {id: "created_at.asc", text: "Created - Oldest First"},
      {id: "created_at.desc", text: "Created - Newest First"},
      {id: "issued_date.asc", text: "Issued Date - Oldest First"},
      {id: "issued_date.desc", text: "Issued Date- Newest First"},
      {id: "processed_on.asc", text: "Proccessed On - Oldest First"},
      {id: "processed_on.desc", text: "Proccessed On - Newest First"}
    ]
  end

  def primary_user_kyc
    if self.project_unit_id.present? && self.project_unit.user_id == self.user_id
      return self.project_unit.primary_user_kyc
    else
      return UserKyc.where(user_id: self.user_id).asc(:created_at).first
    end
  end

  def payment_gateway_service
    if self.payment_gateway.present?
      if self.project_unit.present? && (ProjectUnit.booking_stages.exclude?(self.project_unit.status) && self.project_unit.status != "hold")
        return nil
      else
        if(self.project_unit.blank? || self.project_unit.user_id == self.user_id)
          return eval("PaymentGatewayService::#{self.payment_gateway}").new(self)
        else
          return nil
        end
      end
    else
      return nil
    end
  end

  def blocking_payment?
    self.project_unit_id.present? && self.project_unit.receipts.in(status: ["success", "clearance_pending"]).count == 0
  end

  def generate_receipt_id
    if self.status == "success"
      self.assign!(:order_id) if self.order_id.blank?
      if self.project_unit_id.present?
        "#{self.user.booking_portal_client.name[0..1].upcase}-#{self.project_unit.name[0..1].upcase}-#{self.order_id}"
      else
        "#{self.user.booking_portal_client.name[0..1].upcase}-#{self.order_id}"
      end
    elsif self.receipt_id.blank?
      "#{self.user.booking_portal_client.name[0..1].upcase}-TMP-#{SecureRandom.hex(4)}"
    else
      self.receipt_id
    end
  end

  def self.user_based_scope(user, params={})
    custom_scope = {}
    if params[:user_id].blank? && !user.buyer?
      if user.role?('channel_partner')
        custom_scope = {user_id: {"$in": User.where(referenced_manager_ids: user.id).distinct(:id)}}
      elsif user.role?('cp_admin')
        custom_scope = {user_id: {"$in": User.where(role: "user").nin(manager_id: [nil, ""]).distinct(:id)}}
      elsif user.role?('cp')
        channel_partner_ids = User.where(role: "channel_partner").where(manager_id: user.id).distinct(:id)
        custom_scope = {user_id: {"$in": User.in(referenced_manager_ids: channel_partner_ids).distinct(:id)}}
      end
    end

    custom_scope = {user_id: params[:user_id]} if params[:user_id].present?
    custom_scope = {user_id: user.id} if user.buyer?

    custom_scope[:project_unit_id] = params[:project_unit_id] if params[:project_unit_id].present?
    custom_scope
  end

  #
  # Initial Payment should be greater than blocking amount.
  #
  #
  def first_booking_amount_limit
    if self.project_unit.try(:status) == 'hold'
      if self.total_amount < self.project_unit.blocking_amount
        self.errors.add(:total_amount, "should be greater than blocking amount(#{self.project_unit.blocking_amount})")
      end
    end
  end

  private
  def validate_total_amount
    if self.total_amount <= 0
      self.errors.add :total_amount, "cannot be less than or equal to 0"
    end

    blocking_amount = self.user.booking_portal_client.blocking_amount
    if self.project_unit_id.present?
      blocking_amount = self.project_unit.blocking_amount
    end
    if (self.project_unit_id.blank? || self.blocking_payment?) && self.total_amount < blocking_amount && self.new_record? && !self.swap_request_initiated
      self.errors.add :total_amount, "cannot be less than blocking amount #{self.user.booking_portal_client.blocking_amount}"
    end
  end

  def tracking_id_processed_on_only_on_success
    if self.status_changed? && self.status != "success" && self.payment_mode != "online"
      self.errors.add :tracking_id, 'cannot be set unless the status is marked as success' if self.tracking_id_changed? && self.tracking_id.present?
      self.errors.add :processed_on, 'cannot be set unless the status is marked as success' if self.processed_on_changed? && self.processed_on.present?
    end
  end

  def processed_on_greater_than_issued_date
    if self.processed_on.present? && self.issued_date.present? && self.processed_on < self.issued_date
      self.errors.add :processed_on, 'cannot be older than the Issued Date'
    end
  end
end
