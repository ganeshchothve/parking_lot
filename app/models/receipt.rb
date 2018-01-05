class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :receipt_id, type: String
  field :acounting_date, type: Date
  field :payment_mode, type: String, default: 'online'
  field :issued_date, type: Date # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :tds_challan, type: Boolean
  field :total_amount, type: Float, default: 0 # Total amount
  field :status, type: String, default: 'pending' # pending, success, failed, clearance_pending
  field :payment_type, type: String, default: 'blocking' # blocking, booking
  field :reference_project_unit_id, type: BSON::ObjectId # the channel partner or admin can choose this, but its not binding on the user to choose this reference unit

  belongs_to :user, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :creator, class_name: 'User'

  validates :receipt_id, :total_amount, :status, :payment_mode, :payment_type, :user_id, presence: true
  validates :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_mode != 'online' || (receipt.payment_type == 'online' && receipt.status != 'pending')}
  validates :project_unit_id, presence: true, if: Proc.new{|receipt| receipt.payment_type != 'blocking'} # allow the user to make a blocking payment without any unit
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }
  validates :payment_type, inclusion: {in: Proc.new{ Receipt.available_payment_types.collect{|x| x[:id]} } }
  validates :payment_mode, inclusion: {in: Proc.new{ Receipt.available_payment_modes.collect{|x| x[:id]} } }
  validates :reference_project_unit_id, presence: true, if: Proc.new{ |receipt| receipt.creator.role != 'user' }
  validate :validate_total_amount
  validate :status_changed

  default_scope -> {desc(:created_at)}

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

  private
  def validate_total_amount
    if self.total_amount < ProjectUnit.blocking_amount && self.project_unit_id.blank?
      self.errors.add :total_amount, " cannot be less than or equal to #{ProjectUnit.blocking_amount}"
    end
    if self.total_amount <= 0
      self.errors.add :total_amount, " cannot be less than or equal to 0"
    end
    if self.new_record? && self.project_unit.present? && (self.total_amount > self.project_unit.pending_balance)
      self.errors.add :total_amount, " cannot be greater than #{self.project_unit.pending_balance}"
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
