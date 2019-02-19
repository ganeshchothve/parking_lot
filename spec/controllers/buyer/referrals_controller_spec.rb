require 'rails_helper'
RSpec.describe Buyer::ReferralsController, type: :controller do
  describe "GET index" do
    before(:each) do
      @user = create(:user, booking_portal_client: Client.asc(:created_at).first )
      sign_in_app(@user)
    end

    it "success response" do
      get :index
      expect(response.status).to eq(200)
    end
  end
end