require 'autoinc'
class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  include ReceiptStateMachine

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
  validate :tracking_id_processed_on_only_on_success
  validate :processed_on_greater_than_issued_date

  increments :order_id, auto: false
  default_scope -> {desc(:created_at)}

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

  def primary_user_kyc
    if self.project_unit_id.present? && self.project_unit.user_id == self.user_id
      return self.project_unit.primary_user_kyc
    else
      return UserKyc.where(user_id: self.user_id).asc(:created_at).first
    end
  end

  def payment_gateway_service
    if self.payment_gateway.present?
      if self.project_unit.present? && ["hold", "blocked", "booked_tentative", "booked_confirmed"].exclude?(self.project_unit.status)
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

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:status].present?
        selector[:status] = params[:fltrs][:status]
      end
      if params[:fltrs][:receipt_id].present?
        selector[:receipt_id] = params[:fltrs][:receipt_id]
      end
      if params[:fltrs][:user_id].present?
        selector[:user_id] = params[:fltrs][:user_id]
      end
      if params[:fltrs][:project_unit_id].present?
        selector[:project_unit_id] = params[:fltrs][:project_unit_id]
      end
      if params[:project_unit_id].present?
        selector[:project_unit_id] = params[:project_unit_id]
      end
      if params[:fltrs][:payment_mode].present?
        selector[:payment_mode] = params[:fltrs][:payment_mode]
      end
    end
    selector1 = {}
    if params[:fltrs].blank? || params[:fltrs][:status].blank?
      selector1 = {"$or": [{status: "pending", payment_mode: {"$ne" => "online"}}, {status: {"$ne" => "pending"}}]}
    end
    or_selector = {}
    if params[:q].present?
      regex = ::Regexp.new(::Regexp.escape(params[:q]), 'i')
      or_selector = {"$or": [{receip_id: regex}, {tracking_id: regex}, {payment_identifier: regex}] }
    end
    selector = self.and([selector, selector1, or_selector])
    selector
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

  private
  def validate_total_amount
    if self.total_amount <= 0
      self.errors.add :total_amount, "cannot be less than or equal to 0"
    end

    if (self.project_unit_id.blank? || self.blocking_payment?) && self.total_amount < self.user.booking_portal_client.blocking_amount
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
