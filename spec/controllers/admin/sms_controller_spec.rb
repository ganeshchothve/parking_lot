require 'rails_helper'
RSpec.describe Admin::SmsesController, type: :controller do
  describe "check policy scope for smses" do
    before (:each) do
      @user = create(:admin)
      another_user = create(:user)
      @sms1 = create(:sms, recipient_id: @user.id)
      sms2 = create(:sms, recipient_id: @user.id)
      @sms3 = create(:sms, recipient_id: another_user.id)
      sign_in_app(@user)
    end
    it "index action" do
      sms_count = Sms.count
      get :index
      expect(assigns(:smses).count).to eq(sms_count)
    end
    it "show action(admin is allowed to view all the emails)" do
      get :show, params: { id: @sms3.id }
      expect(response.status).to eq(200)
    end
  end
end