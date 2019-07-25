class Account::CcAvenuePayment < Account
  field :merchant_id, type: String
  field :access_code, type: String # required true
  field :working_key, type: String # required true

  validates :merchant_id, :working_key, :access_code, presence: true
  validate :donot_change_account_details, on: :update

  def donot_change_account_details
    if ('access_code'.in?(self.changes.keys) || 'merchant_id'.in?(self.changes.keys)) && self.receipts.any?
      self.errors.add(:base, 'You have some associated receipts. Please add another account and link it in respective phase.')
    end
  end

end
