require 'rails_helper'
RSpec.describe Admin::BookingDetails::BookingDetailSchemesController, type: :controller do
  describe 'creating booking_detail_scheme' do
    it 'booking_detail_scheme is created for every booking' do
      client = Client.first || create(:client)
      admin = create(:admin)
      sign_in_app(admin)

      @user = create(:user)
      client.enable_actual_inventory << admin.role
      client.save
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      project_tower = create(:project_tower)
      @project_unit = create(:project_unit, project_tower: project_tower)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: "filter", results_count: nil, user_id: @user.id )
      pubs = ProjectUnitBookingService.new(@project_unit)
      pubs.create_booking_detail (search.id)
      booking_detail_scheme_params = FactoryBot.attributes_for(:booking_detail_scheme)
      booking_detail_scheme_params[:derived_from_scheme_id] = Scheme.first.id
      post :create, params: { booking_detail_scheme: booking_detail_scheme_params, user_id: @user.id, booking_detail_id: @project_unit.booking_detail.id }
      expect(BookingDetailScheme.first.booking_detail.id).to eq(@project_unit.booking_detail.id)
    end
  end
end
