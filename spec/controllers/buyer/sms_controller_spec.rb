require 'rails_helper'
RSpec.describe Buyer::SmsesController, type: :controller do
  describe "check policy scope for emails" do
    before (:each) do
      @user = create(:user)
      another_user = create(:user)
      @sms1 = create(:sms, recipient_id: @user.id)
      sms2 = create(:sms, recipient_id: @user.id)
      @sms3 = create(:sms, recipient_id: another_user.id)
      sign_in_app(@user)
    end
    it "index action" do
      sms_count = Sms.where(recipient_id: @user.id).count
      get :index
      expect(assigns(:smses).count).to eq(sms_count)
    end
    it "show action(buyer is not allowed to view this email)" do
      get :show, params: { id: @sms3.id }
      expect(response.status).to eq(302)
    end
    it "show action(buyer is allowed to view this email)" do
      get :show, params: { id: @sms1.id }
      expect(response.status).to eq(200)
    end
  end
end