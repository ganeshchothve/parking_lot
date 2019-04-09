require 'rails_helper'
RSpec.describe Admin::ProjectUnitsController, type: :controller do
  describe "Admin side" do
    before(:each) do
      @client = Client.first || create(:client)
      @admin = create(:admin)
      @user = create(:user)
      sign_in_app(@admin)
    end
    describe "release_project unit" do
      before(:each) do
        @booking_detail = booking_under_negotiation(@user)
        @booking_detail_scheme = @booking_detail.booking_detail_scheme
        @booking_detail_scheme.rejected!
        patch :release_unit, params: { id: @booking_detail.project_unit.id, project_unit: @booking_detail.project_unit }
      end
      it "project_unit_status changes to available" do
        expect(@booking_detail.project_unit.status).to eq('available') 
      end
      it "booking_detail status changes to cancelled" do
        expect(@booking_detail.status).to eq('cancelled')
      end
    end
  end
end