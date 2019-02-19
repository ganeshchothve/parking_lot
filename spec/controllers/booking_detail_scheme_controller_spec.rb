require 'rails_helper'
RSpec.describe BookingDetailSchemesController, type: :controller do
  describe "updating booking detail scheme" do
    before(:each) do
      @admin = create(:admin, booking_portal_client: Client.asc(:created_at).first )
      sign_in_app(@admin)
      @user = create(:user, booking_portal_client: Client.asc(:created_at).first )
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit, booking_portal_client: Client.asc(:created_at).first )
    end

    it "success response" do
      # debugger
    end
  end
end