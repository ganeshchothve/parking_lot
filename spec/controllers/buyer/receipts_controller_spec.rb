require 'rails_helper'
RSpec.describe Buyer::ReceiptsController, type: :controller do
  describe "creating receipt" do
    before(:each) do
      default = Account::RazorpayPayment.new(account_number: '123412341234', by_default: 'true', key: 'rzp_test_NTQGRS3ia0hiWY', secret: "pzM04pY4CJFkHbM3iWKBjDhN" )
      default.save
      not_default = Account::RazorpayPayment.new(account_number: '123412341235', by_default: 'false', key: 'rzp_test_NTQGRS3ia0hiWY', secret: "pzM04pY4CJFkHbM3iWKBjDhN" )
      not_default.save
      client = create(:client)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      sign_in_app(@user)
    end
    it "selects default account when any tower is not selected" do
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: {receipt: receipt_params}
      expect(Receipt.first.account.by_default).to eq(true)
    end
  end
end