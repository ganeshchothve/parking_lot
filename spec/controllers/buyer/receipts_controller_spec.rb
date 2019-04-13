require 'rails_helper'
RSpec.describe Buyer::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      sign_in_app(@user)
    end
    it 'selects default account when any unit is not selected' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params }
      receipt = Receipt.first
      receipt.success!
      expect(receipt.account.by_default).to eq(true)
    end

    describe 'direct payment' do
      it 'if user is unconfirmed, flash will contain error message' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        @user.set(confirmed_at: nil)
        post :create, params: { receipt: receipt_params }
        expect(response.request.flash[:alert]).to eq('You have to confirm your email address before continuing.')
      end

      it 'if user has not filled in kyc details, flash will contain error message' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        User.any_instance.stub(:kyc_ready?).and_return false
        post :create, params: { receipt: receipt_params }
        expect(response.request.flash[:alert].present?).to eq(true)
      end

      it 'if client has set enable_direct_payment to false, flash will contain error message' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Client.first.set(enable_direct_payment: false)
        post :create, params: { receipt: receipt_params }
        expect(response.request.flash[:alert]).to eq('Direct payment is not available right now.')
      end

      it 'redirects to searches controller payment_gateway function on successful save' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        post :create, params: { receipt: receipt_params }
        receipt = Receipt.first
        search_id = receipt.user.searches.desc(:created_at).first.id
        expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
      end

      it 'if receipt payment gateway service absent, redirects to dashboard' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:payment_gateway_service).and_return nil
        post :create, params: { receipt: receipt_params }
        receipt = Receipt.first
        expect(response.request.flash[:notice]).to eq("We couldn't redirect you to the payment gateway, please try again")
        expect(receipt.status).to eq('failed')
        expect(response).to redirect_to(dashboard_path)
      end

      it 'if saving receipt is unsuccessful, render new' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:save).and_return false
        Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
        post :create, params: { receipt: receipt_params }
        expect(response).to render_template('new')
      end

      it 'if receipt account blank, render new ' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:account).and_return nil
        post :create, params: { receipt: receipt_params }
        expect(response.request.flash[:alert]).to eq('We do not have any Account Details for Transaction. Please ask Administrator to add.')
        expect(response).to render_template('new')
      end

      it 'redirects to searches controller payment_gateway function on successful save' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        post :create, params: { receipt: receipt_params }
        receipt = Receipt.first
        search_id = receipt.user.searches.desc(:created_at).first.id
        expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
      end

      it 'if receipt payment gateway service absent, redirects to dashboard' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:payment_gateway_service).and_return nil
        post :create, params: { receipt: receipt_params }
        receipt = Receipt.first
        expect(response.request.flash[:notice]).to eq("We couldn't redirect you to the payment gateway, please try again")
        expect(receipt.status).to eq('failed')
        expect(response).to redirect_to(dashboard_path)
      end

      it 'if saving receipt is unsuccessful, render new' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:save).and_return false
        Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
        post :create, params: { receipt: receipt_params }
        expect(response).to render_template('new')
      end

      it 'if receipt account blank, render new ' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:account).and_return nil
        post :create, params: { receipt: receipt_params }
        expect(response.request.flash[:alert]).to eq('We do not have any Account Details for Transaction. Please ask Administrator to add.')
        expect(response).to render_template('new')
      end
    end
  end
end

# context '' do
#   %i[user employee_user management_user].each do |role|
# before(:each) do
#   phase = create(:phase)
#   default = create(:razorpay_payment, by_default: true)
#   not_default = create(:razorpay_payment, by_default: false)
#   not_default.phases << phase
#   @client = create(:client)
#   @user = create(:user)
#   kyc = create(:user_kyc, creator_id: @user.id, user: @user)
#   sign_in_app(@user)
# end

# end
#   end
# end

# BookingDetailScheme.any_instance.stub(:save).and_return false
# BookingDetailScheme.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(BookingDetailScheme.new).tap { |e| e.add(:project_unit, 'cannot be blank') })

# allow_any_instance_of(Receipt).to receive(:confirmed_at).and_return(nil)
