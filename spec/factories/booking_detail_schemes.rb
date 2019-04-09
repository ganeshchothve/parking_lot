FactoryBot.define do
  factory :booking_detail_scheme do
    # field :derived_from_scheme_id, type: BSON::ObjectId
    # status {"draft"}
    approved_at { DateTime.now }
   # field :user_id, type: BSON::ObjectId

  after(:build) do |booking_detail_scheme|
      booking_detail_scheme.project_unit ||= ProjectUnit.desc(:created_at).first || create(:project_unit)
      booking_detail_scheme.booking_detail ||= BookingDetail.desc(:created_at).first
      booking_detail_scheme.created_by ||= User.where(role: 'admin').first || create(:admin)
      booking_detail_scheme.approved_by ||= User.where(role: 'admin').first || create(:admin)
      booking_detail_scheme.booking_portal_client ||= Client.desc(:created_by).first || create(:client)
      booking_detail_scheme.derived_from_scheme_id = Scheme.first.id || create(:scheme).id
      booking_detail_scheme.payment_adjustments << FactoryBot.build(:payment_adjustment)
    end 
    after(:create) do |booking_detail_scheme|
      booking_detail_scheme.derived_from_scheme_id = Scheme.first.id || create(:scheme).id
    end
  end
end
