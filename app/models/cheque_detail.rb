class ChequeDetail
  include Mongoid::Document
  include Mongoid::Timestamps

  field :issued_date, type: Date # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :handover_date, type: Date
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :total_amount, type: Float

  validates :total_amount, :payment_identifier, :issued_date, :handover_date, :issuing_bank, :issuing_bank_branch, presence: true
  validates :issuing_bank, :issuing_bank_branch, name: true
  validates :total_amount, numericality: { greater_than: 0 }

  belongs_to :creator, class_name: 'User'
  embedded_in :invoice
end
