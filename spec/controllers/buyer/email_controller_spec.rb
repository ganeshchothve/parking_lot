require 'rails_helper'
RSpec.describe Buyer::EmailsController, type: :controller do
  describe "check policy scope for emails" do
    before (:each) do
      @user = create(:user)
      another_user = create(:user)
      @email1 = create(:email, recipient_ids: [@user.id])
      email2 = create(:email, recipient_ids: [@user.id])
      @email3 = create(:email, recipient_ids: [another_user.id])
      sign_in_app(@user)
    end
    it "index action" do
      email_count = Email.where(recipient_ids: @user.id).count
      get :index
      expect(assigns(:emails).count).to eq(email_count)
    end
    it "show action(buyer is not allowed to view this email)" do
      get :show, params: { id: @email3.id }
      expect(response.status).to eq(302)
    end
    it "show action(buyer is allowed to view this email)" do
      get :show, params: { id: @email1.id }
      expect(response.status).to eq(200)
    end
  end
end