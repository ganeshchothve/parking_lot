class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :account_number, type: Integer #required true
  field :is_active, type: Boolean, default: false #required true

  validates_uniqueness_of :account_number

  has_many :receipts
  has_many :project_towers
end
