require 'autoinc'
class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc
  include ArrayBlankRejectable
  include Mongoid::Autoinc

  field :receipt_id, type: String
  field :order_id, type: String
  field :payment_mode, type: String, default: 'online'
  field :issued_date, type: Date # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :tracking_id, type: String # cheque / DD number / online transaction reference from gateway
  field :total_amount, type: Float, default: 0 # Total amount
  field :status, type: String, default: 'pending' # pending, success, failed, clearance_pending
  field :status_message, type: String # pending, success, failed, clearance_pending
  field :payment_type, type: String, default: 'blocking' # blocking, booking
  field :reference_project_unit_id, type: BSON::ObjectId # the channel partner or admin can choose this, but its not binding on the user to choose this reference unit
  field :payment_gateway, type: BSON::ObjectId

  increments :order_id

  belongs_to :user, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :creator, class_name: 'User'

  validates :receipt_id, :total_amount, :status, :payment_mode, :payment_type, :user_id, presence: true
  validates :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_type == 'online' && receipt.status != 'pending' }
  validates :project_unit_id, presence: true, if: Proc.new{|receipt| receipt.payment_type != 'blocking'} # allow the user to make a blocking payment without any unit
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }
  validates :payment_type, inclusion: {in: Proc.new{ Receipt.available_payment_types.collect{|x| x[:id]} } }
  validates :payment_mode, inclusion: {in: Proc.new{ Receipt.available_payment_modes.collect{|x| x[:id]} } }
  validates :reference_project_unit_id, presence: true, if: Proc.new{ |receipt| receipt.creator.role != 'user' }
  validate :validate_total_amount
  validates :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_mode != 'online' }
  validates :payment_gateway, presence: true, if: Proc.new{|receipt| receipt.payment_mode == 'online' }
  validates :payment_gateway, inclusion: {in: PaymentGatewayService::Default.allowed_payment_gateways }, allow_blank: true
  validate :status_changed

  increments :order_id
  default_scope -> {desc(:created_at)}

  def reference_project_unit
    if self.reference_project_unit_id.present?
      ProjectUnit.find(self.reference_project_unit_id)
    else
      nil
    end
  end

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'success', text: 'Success'},
      {id: 'clearance_pending', text: 'Pending Clearance'},
      {id: 'failed', text: 'Failed'}
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

  def payment_gateway_service
    if self.payment_gateway.present?
      if self.project_unit.present? && ["available", "not_available", "error", "booked_confirmed"].include?(self.project_unit.status)
        return nil
      else
        return eval("PaymentGatewayService::#{self.payment_gateway}").new(self)
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
      if params[:fltrs][:user_id].present?
        selector[:user_id] = params[:fltrs][:user_id]
      end
      if params[:fltrs][:payment_mode].present?
        selector[:payment_mode] = params[:fltrs][:payment_mode]
      end
      if params[:fltrs][:payment_type].present?
        selector[:payment_type] = params[:fltrs][:payment_type]
      end
    end
    self.where(selector)
  end

  private
  def validate_total_amount
    if self.total_amount < ProjectUnit.blocking_amount && self.project_unit_id.blank? && self.new_record?
      self.errors.add :total_amount, " cannot be less than #{ProjectUnit.blocking_amount}"
    end
    if self.total_amount <= 0
      self.errors.add :total_amount, " cannot be less than or equal to 0"
    end
    if self.project_unit_id.present? && (self.total_amount > self.project_unit.pending_balance) && self.new_record?
      self.errors.add :total_amount, " cannot be greater than #{self.project_unit.pending_balance}"
    end
    if self.reference_project_unit_id.present? && (self.total_amount > self.reference_project_unit.pending_balance({user_id: self.user_id})) && self.new_record?
      self.errors.add :total_amount, " cannot be greater than #{self.reference_project_unit.pending_balance({user_id: self.user_id})}"
    end
  end

  def status_changed
    if self.status_changed? && ['success', 'failed'].include?(self.status_was)
      self.errors.add :status, ' cannot be modified for a successful or failed payments'
    end
    if self.status_changed? && ['clearance_pending'].include?(self.status_was) && self.status == 'pending'
      self.errors.add :status, ' cannot be modified to "pending" from "Pending Clearance" status'
    end
  end
end
