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

  belongs_to :bankable, polymorphic: true

  validates :account_type, inclusion: {in: Proc.new{ BankDetail.available_account_types.collect{|x| x[:id]} } }

  def self.available_account_types
    [
      {id: 'savings', text: 'Savings'},
      {id: 'current', text: 'Current'}
    ]
  end
end
