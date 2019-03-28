FactoryBot.define do
  factory :booking_detail do
 # field :primary_user_kyc_id, type: BSON::ObjectId

   after(:build) do |booking_detail|
      booking_detail.project_unit ||= ProjectUnit.desc(:created_at).first || create(:project_unit)
    end
  end
end