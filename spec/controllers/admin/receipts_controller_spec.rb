require 'rails_helper'
RSpec.describe Admin::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      client = create(:client)
      admin = create(:admin)
      sign_in_app(admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
    end
    it 'selects default account when any unit is not selected' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      receipt = Receipt.first
      receipt.success!
      expect(receipt.account.by_default).to eq(true)
    end
  end
end
