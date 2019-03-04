FactoryBot.define do
  factory :email do
    to { [Faker::Internet.email] }
    cc { [Faker::Internet.email] }
    subject { Faker::String.random(3) }
    body { Faker::String.random(3) }
    text_only_body { Faker::String.random(3) }
    status 'draft'
    remote_id { Faker::String.random(3) }
    sent_on { Faker::Time.between(DateTime.now - 1, DateTime.now) }
    before(:create) do |email| 
      email.recipient_ids << User.first.id || create(:user).id if email.recipient_ids.empty?
      email.triggered_by = Receipt.first || create(:receipt)
      email.booking_portal_client = Client.first
    end
  end

end