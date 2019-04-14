require 'rails_helper'
RSpec.describe Admin::ReceiptsController, type: :controller do
  describe 'creating lost receipt' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      @not_default = create(:razorpay_payment, by_default: false)
      @not_default.phases << phase
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
  describe 'block in creating lost receipt' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      @not_default = create(:razorpay_payment, by_default: false)
      @not_default.phases << phase
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

  describe 'direct payment' do
    # context '' do
    #   %i[user employee_user management_user].each do |role|
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      admin = create(:admin)
      sign_in_app(admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
    end

    it 'if user is unconfirmed, flash will contain error message' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
      @user.set(confirmed_at: nil)
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response.request.flash[:alert]).to eq('Associated User is not yet confirmed.')
    end

    it 'if user has not filled in kyc details, flash will contain error message' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
      User.any_instance.stub(:kyc_ready?).and_return false
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response.request.flash[:alert]).to eq("Associated User's KYC is missing.")
    end

    it 'if client has set enable_direct_payment to false, flash will contain error message' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
      Client.first.set(enable_direct_payment: false)
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response.request.flash[:alert]).to eq('Direct payment is not available right now.')
    end

    # it 'if client has set enable_direct_payment to false, flash will contain error message' do
    #   receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
    #   @user.set(role: 'channel_partner')
    #   post :create, params: { receipt: receipt_params, user_id: @user.id }
    #   expect(response.request.flash[:alert]).to eq("Direct payment is not available right now.")
    # end

    it 'redirects to searches controller payment_gateway function on successful save when payment_identifier is nil' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      receipt = Receipt.first
      search_id = receipt.user.searches.desc(:created_at).first.id
      expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
      expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
    end

    it 'redirects to admin_user_receipts_path successful save when payment_identifier is present' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online')
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      receipt = Receipt.first
      expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
      expect(response).to redirect_to(admin_user_receipts_path(@user))
    end

    it 'if saving receipt is unsuccessful, render new' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online')
      Receipt.any_instance.stub(:save).and_return false
      Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response).to render_template('new')
    end

    it 'if receipt account blank, render new ' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online')
      Receipt.any_instance.stub(:account).and_return nil
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response.request.flash[:alert]).to eq('We do not have any Account Details for Transaction. Please ask Administrator to add.')
      expect(response).to render_template('new')
    end
    # end
  end
end
