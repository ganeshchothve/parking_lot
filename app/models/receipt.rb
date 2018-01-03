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

  validates :receipt_id, :total_amount, :status, :payment_mode, :payment_type, :user_id, presence: true
  validates :project_unit_id, presence: true, if: Proc.new{|receipt| receipt.payment_type != 'blocking'} # allow the user to make a blocking payment without any unit
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }
  validates :payment_type, inclusion: {in: Proc.new{ Receipt.available_payment_types.collect{|x| x[:id]} } }
  validate :validate_total_amount

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
      {id: 'booking', text: 'Booking'}
    ]
  end

  private
  def validate_total_amount
    if self.total_amount <= 0
      self.errors.add :total_amount, ' cannot be less than 0'
    end

    if self.payment_type == 'booking'
      if self.total_amount > self.project_unit.pending_balance
        self.errors.add :total_amount, " cannot be greater than #{self.project_unit.pending_balance}"
      end
    end
  end
end
