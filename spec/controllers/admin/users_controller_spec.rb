require 'rails_helper'
RSpec.describe Admin::UsersController, type: :controller do
  describe "GET index" do
    it "success response" do
      admin = create(:admin)
      sign_in_app(admin)
      get :index
      expect(response.status).to eq(200)
    end
  end
end