class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :account_number, type: Integer # required true

  validates_uniqueness_of :account_number

  has_many :receipts
  has_many :phases

  before_destroy :check_for_receipts

  private 
  def check_for_receipts
    if receipts.count > 0 
      errors.add_to_base("cannot delete account while receipts exist")
      return false
    end
  end
end
