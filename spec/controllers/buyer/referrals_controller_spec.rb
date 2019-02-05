require 'rails_helper'
RSpec.describe Buyer::ReferralsController, type: :controller do
  describe "GET index" do
    before(:each) do
      @user = create(:user)
      sign_in_app(@user)
    end
    it "success response" do
      get :index
      expect(response.status).to eq(200)
    end
  end
end