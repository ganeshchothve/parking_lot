class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :receipt_id, type: String
  field :acounting_date, type: Date
  field :payment_mode, type: String, default: 'online'
  field :issued_date, type: String # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :tds_challan, type: Boolean
  field :total_amount, type: Float, default: 0 # Total amount
  field :status, type: String, default: 'pending' # pending, success, failed
  field :payment_type, type: String, default: 'blocking' # blocking, booking

  belongs_to :user, optional: true
  belongs_to :project_unit, optional: true

  validates :total_amount, :status, :payment_mode, :payment_type, :user_id, presence: true
  validates :project_unit_id, presence: true, if: Proc.new{|receipt| receipt.payment_type != 'blocking'} # allow the user to make a blocking payment without any unit
  validates :total_amount, numericality: { greater_than: 0 }
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }
  validates :payment_type, inclusion: {in: Proc.new{ Receipt.available_payment_types.collect{|x| x[:id]} } }

  default_scope -> {desc(:created_at)}

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'success', text: 'Success'},
      {id: 'failed', text: 'Failed'}
    ]
  end

  def self.available_payment_types
    [
      {id: 'blocking', text: 'Blocking'},
      {id: 'Booking', text: 'Booking'}
    ]
  end
end
