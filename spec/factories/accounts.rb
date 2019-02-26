FactoryBot.define do
  factory :account do
    account_number { Faker::Number.number(8) }
    name { Faker::Name.name }
  end
  factory :razorpay_payment, parent: :account, class: 'Account::RazorpayPayment' do
    key { 'rzp_test_NTQGRS3ia0hiWY' }
    secret { 'pzM04pY4CJFkHbM3iWKBjDhN' }
    by_default { 'false' }
  end
end
