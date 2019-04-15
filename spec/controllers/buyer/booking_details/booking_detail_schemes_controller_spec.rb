require 'rails_helper'
RSpec.describe Buyer::BookingDetails::BookingDetailSchemesController, type: :controller do
  describe 'creating booking_detail_scheme' do
    it 'booking_detail_scheme is created for every booking' do
      client = Client.first || create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      client.enable_actual_inventory << @user.role
      client.save

      booking_detail = book_project_unit(@user, nil, nil, 'hold')
      search = booking_detail.search
      @project_unit = booking_detail.project_unit

      booking_detail_scheme_params = FactoryBot.attributes_for(:booking_detail_scheme)
      booking_detail_scheme_params[:derived_from_scheme_id] = Scheme.first.id
      post :create, params: { booking_detail_scheme: booking_detail_scheme_params, user_id: @user.id, booking_detail_id: @project_unit.booking_detail.id}
      expect(BookingDetailScheme.first.booking_detail.id).to eq(@project_unit.booking_detail.id)
    end
  end
end
