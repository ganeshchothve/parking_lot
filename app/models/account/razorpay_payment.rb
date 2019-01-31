class Account::RazorpayPayment < Account
    field :key, type: String # required true
    field :secret, type: String # required true
    field :by_default, type: Boolean, default: false

    validates :key, :secret, presence: true
  end