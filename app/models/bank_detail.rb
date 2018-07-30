class BankDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :branch, type: String
  field :account_type, type: String
  field :ifsc_code, type: String
  field :account_number, type: String
  field :loan_required, type: Boolean, default: false

  belongs_to :bankable, polymorphic: true

  # has_one :cheque, as: :assetable
end
