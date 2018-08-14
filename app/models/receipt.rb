require 'autoinc'
class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc
  include ArrayBlankRejectable
  include Mongoid::Autoinc
  include InsertionStringMethods
  include ApplicationHelper

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
  field :payment_type, type: String, default: 'blocking' # blocking, booking
  field :payment_gateway, type: BSON::ObjectId
  field :processed_on, type: Date
  field :comments, type: String
  field :gateway_response, type: Hash

  belongs_to :user
  belongs_to :booking_detail, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :creator, class_name: 'User'
  has_many :assets, as: :assetable
  has_many :smses, as: :triggered_by, class_name: "Sms"

  validates :total_amount, :status, :payment_mode, :payment_type, :user_id, presence: true
  validates :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_type == 'online' && receipt.status != 'pending' }
  validates :project_unit_id, presence: true, if: Proc.new{|receipt| receipt.payment_type != 'blocking'} # allow the user to make a blocking payment without any unit
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }
  validates :payment_type, inclusion: {in: Proc.new{ Receipt.available_payment_types.collect{|x| x[:id]} } }
  validates :payment_mode, inclusion: {in: Proc.new{ Receipt.available_payment_modes.collect{|x| x[:id]} } }
  validate :validate_total_amount
  validates :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_mode != 'online' }
  validates :payment_gateway, presence: true, if: Proc.new{|receipt| receipt.payment_mode == 'online' }
  validates :payment_gateway, inclusion: {in: PaymentGatewayService::Default.allowed_payment_gateways }, allow_blank: true
  validate :status_changed
  validates :tracking_id, presence: true, if: Proc.new{|receipt| receipt.status == 'success' && receipt.payment_type != "online"}
  validates :comments, presence: true, if: Proc.new{|receipt| receipt.status == 'failed' && receipt.payment_type != "online"}
  validate :tracking_id_processed_on_only_on_success

  increments :order_id, auto: false
  default_scope -> {desc(:created_at)}

  enable_audit({
    associated_with: ["user"],
    indexed_fields: [:receipt_id, :order_id, :payment_mode, :tracking_id, :payment_type, :creator_id],
    audit_fields: [:payment_mode, :tracking_id, :total_amount, :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, :status, :status_message, :project_unit_id, :booking_detail_id]
  })

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'success', text: 'Success'},
      {id: 'clearance_pending', text: 'Pending Clearance'},
      {id: 'failed', text: 'Failed'},
      {id: 'cancelled', text: 'Cancelled'}
    ]
  end

  def self.available_payment_modes
    [
      {id: 'online', text: 'Online'},
      {id: 'cheque', text: 'Cheque'},
      {id: 'rtgs', text: 'RTGS'},
      {id: 'neft', text: 'NEFT'}
    ]
  end

  def self.available_payment_types
    [
      {id: 'blocking', text: 'Blocking'},
      {id: 'booking', text: 'Booking'}
    ]
  end

  def primary_user_kyc
    if self.project_unit_id.present?
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
      if params[:fltrs][:payment_type].present?
        selector[:payment_type] = params[:fltrs][:payment_type]
      end
    end
    selector = self.where(selector)
    if params[:fltrs].blank? || params[:fltrs][:status].blank?
      selector = selector.or({status: "pending", payment_mode: {"$ne" => "online"}}, {status: {"$ne" => "pending"}})
    end
    or_selector = {}
    if params[:q].present?
      regex = ::Regexp.new(::Regexp.escape(params[:q]), 'i')
      or_selector = {"$or": [{receip_id: regex}, {tracking_id: regex}, {payment_identifier: regex}] }
    end
    selector = selector.where(or_selector)
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
      if self.project_unit_id.present?
        "#{self.user.booking_portal_client.name[0..1].upcase}-TMP-#{SecureRandom.hex(4)}"
      else
        "#{self.user.booking_portal_client.name[0..1].upcase}-TMP-#{SecureRandom.hex(4)}"
      end
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
        custom_scope = {user_id: {"$in": User.where(role: "user").where(manager_id: {"$exists": true}).distinct(:id)}}
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
    if self.total_amount < current_client.blocking_amount && self.payment_type == "blocking" && self.new_record?
      self.errors.add :total_amount, "cannot be less than #{current_client.blocking_amount}"
    end
    if self.total_amount != current_client.blocking_amount && current_client.blocking_amount_editable && self.new_record? && self.payment_type == "blocking" && !current_client.blocking_amount_editable?
      self.errors.add :total_amount, "has to be #{current_client.blocking_amount}"
    end
    if self.total_amount <= 0
      self.errors.add :total_amount, "cannot be less than or equal to 0"
    end
  end

  def status_changed
    if self.status_changed? && ['success', 'failed'].include?(self.status_was) && ['cancelled'].exclude?(self.status)
      self.errors.add :status, 'cannot be modified for a successful or failed payments'
    end
    if self.status_changed? && ['clearance_pending'].include?(self.status_was) && self.status == 'pending'
      self.errors.add :status, 'cannot be modified to "pending" from "Pending Clearance" status'
    end
  end

  def tracking_id_processed_on_only_on_success
    if self.status_changed? && self.status != "success" && self.payment_mode != "online"
      self.errors.add :tracking_id, 'cannot be set unless the status is marked as success' if self.tracking_id_changed? && self.tracking_id.present?
      self.errors.add :processed_on, 'cannot be set unless the status is marked as success' if self.processed_on_changed? && self.processed_on.present?
    end
  end
end
