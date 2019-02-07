class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :account_number, type: Integer # required true

  validates_uniqueness_of :account_number

  has_many :receipts, foreign_key: 'account_number'
  has_many :phases

  before_destroy :check_for_receipts, prepend: true

  private

  def check_for_receipts
      if receipts.any? 
        self.errors.add :base, 'Cannot delete account which has receipts associated with it.'
        false
        throw(:abort)
      end
  end
end
