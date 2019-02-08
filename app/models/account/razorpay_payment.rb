class Account::RazorpayPayment < Account
  field :key, type: String # required true
  field :secret, type: String # required true

  validates :key, :secret, presence: true

  validate :donot_change_account_details, on: :update


  def donot_change_account_details
    if self.changes.keys.include?('key') && self.receipts.any?
      self.errors.add(:key, 'You have some associated receipts. Please add another account and link it in respective phase.')
    end
  end

end