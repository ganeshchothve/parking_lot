class BankDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :branch, type: String
  field :account_type, type: String
  field :ifsc_code, type: String
  field :account_holder_name, type: String
  field :account_number, type: String
  field :loan_required, type: Boolean, default: false
  field :loan_amount, type: Integer
  field :loan_sanction_days, type: Integer
  field :zip, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :bankable, polymorphic: true, optional: true

  enable_audit({
    associated_with: ["bankable"],
    audit_fields: [:name, :branch, :account_number, :account_type, :ifsc_code, :loan_required],
  })

  # has_one :cheque, as: :assetable
  validates :account_type, inclusion: {in: Proc.new{ BankDetail.available_account_types.collect{|x| x[:id]} } }, allow_blank: true

  def self.available_account_types
    [
      {id: 'savings', text: 'Savings'},
      {id: 'current', text: 'Current'}
    ]
  end
end
