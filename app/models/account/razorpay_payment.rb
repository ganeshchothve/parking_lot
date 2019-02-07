class Account::RazorpayPayment < Account
    field :key, type: String # required true
    field :secret, type: String # required true

    validates :key, :secret, presence: true
  end