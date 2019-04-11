FactoryBot.define do
  factory :receipt do
    order_id { Faker::String.random(5) }
    # payment_mode {['online','cheque','rtgs','imps','card_swipe','neft'].sample}
    receipt_id { Faker::String.random(5) }
    issued_date { Faker::Date.backward(3) } # Date when cheque / DD etc are issued
    issuing_bank { Faker::Name.first_name } # Bank which issued cheque / DD etc
    issuing_bank_branch { Faker::Address.street_name } # Branch of bank
    payment_identifier { Faker::Bank.iban } # cheque / DD number / online transaction reference from gateway
    # status 'pending'
    # tracking_id { Faker::String.random(5) } # online transaction reference from gateway or transaction id after the cheque is processed
    total_amount { Faker::Number.number(6) } # Total amount
    # status { 'success' } # { ['success', 'clearance_pending', 'failed', 'available_for_refund', 'refunded', 'cancelled'].sample } # pending, success, failed, clearance_pending,cancelled
    status_message { Faker::String.random(5) } # pending, success, failed, clearance_pending
    payment_gateway { 'Razorpay' }
    # processed_on { Faker::Date.forward(23) }
    comments { Faker::String.random(5) }
    # gateway_response nil
    association :creator, factory: :user
    association :account, factory: :razorpay_payment
  end

  factory :check_payment, parent: :receipt do
    issued_date { Date.today }
    issuing_bank { 'HDFC' }
    payment_gateway { nil }
    payment_mode { 'cheque' }
    processed_on { Date.today }
    tracking_id { 'test' }
  end
end
