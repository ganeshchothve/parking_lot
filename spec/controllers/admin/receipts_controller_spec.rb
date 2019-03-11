require 'rails_helper'
RSpec.describe Admin::ReceiptsController, type: :controller do
  describe 'creating lost receipt' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      @not_default = create(:razorpay_payment, by_default: false)
      @not_default.phases << phase
      client = create(:client)
      superadmin = create(:superadmin)
      sign_in_app(superadmin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
    end
    it 'selects account which has been selected by the user(default false)' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      receipt_params[:payment_identifier] = 'rz1201'
      receipt_params[:account_number] = @not_default.id
      receipt_params[:payment_mode] = 'online'
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(Receipt.first.account.account_number).to eq(@not_default.account_number)
    end
    it 'after adding lost receipt, user is redirected to admin user index page' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      receipt_params[:payment_identifier] = 'rz1201'
      receipt_params[:account_number] = @not_default.id
      receipt_params[:payment_mode] = 'online'
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response).to redirect_to(admin_user_receipts_path(@user))
    end
  end
  describe "block in creating lost receipt" do 
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      @not_default = create(:razorpay_payment, by_default: false)
      @not_default.phases << phase
      client = create(:client)
      admin = create(:admin)
      sign_in_app(admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
    end
    it 'does not permit account_number to be assigned to receipt' do 
      receipt_params = FactoryBot.attributes_for(:receipt)
      receipt_params[:payment_identifier] = 'rz1201'
      receipt_params[:account_number] = @not_default.id
      receipt_params[:payment_mode] = 'online'
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(Receipt.first.account.account_number).to_not eq(@not_default.account_number)
    end
  end
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
      expect(Receipt.first.account.by_default).to eq(true)
    end
  end
end
