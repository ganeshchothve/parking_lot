require 'rails_helper'
RSpec.describe Admin::UsersController, type: :controller do
  describe "GET index" do
    it "success response" do
      user = create(:user)
      puts user.role
      sign_in_app(user)
      get :index
      expect(response.status).to eq(200)
    end
  end
end