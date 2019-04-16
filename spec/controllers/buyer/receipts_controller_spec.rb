require 'rails_helper'
RSpec.describe Buyer::ReceiptsController, type: :controller do
  describe '#create' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      @not_default = create(:razorpay_payment, by_default: false)
      @not_default.phases << phase
    end

    describe 'creating receipt' do
      User::BUYER_ROLES.each do |user_role|
        describe "For #{user_role}" do
          before(:each) do
            allow_any_instance_of(Client).to receive(:enable_company_users?).and_return(true)
            @user = create(user_role)
            create(:user_kyc, creator_id: @user.id, user: @user)
            sign_in_app(@user)
          end

          it 'selects default account when any unit is not selected' do
            receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
            post :create, params: { receipt: receipt_params, user_id: @user.id }
            receipt = Receipt.first
            receipt.success!
            expect(receipt.account.by_default).to eq(true)
          end

          it 'send alert message when account is missing' do
            allow_any_instance_of(Receipt).to receive(:account).and_return(nil)
            receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
            post :create, params: { receipt: receipt_params, user_id: @user.id }
            expect(response.request.flash[:alert]).to eq('Any Account is not linked yet. Please contact to admin.')
          end

          it 'send alert message when receipts is invalid' do
            receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil, total_amount: 0 )
            post :create, params: { receipt: receipt_params, user_id: @user.id }
            expect(response.request.flash[:alert]).to eq(["Total Amount (Rs.) cannot be less than or equal to 0"])
          end

          describe 'payment is offline' do
            Receipt::OFFLINE_PAYMENT_MODE.each do |payment_mode|
              before(:each) do
                @receipt_params = FactoryBot.attributes_for(:receipt,payment_mode: payment_mode)
              end
              it "redirects to users receipts index page when receipt payment_mode #{payment_mode}" do
                post :create, params: { receipt: @receipt_params, user_id: @user.id }
                expect(response.request.flash[:alert]).to eq('Only Online payment is permitted.')
              end
            end
          end

          describe 'payment_mode is online' do
            it "redirects to payment link when receipt has no payment_identifier " do
              receipt_params = FactoryBot.attributes_for(:receipt,payment_mode: 'online', payment_identifier: nil)
              post :create, params: { receipt: receipt_params, user_id: @user.id }
              expect(response).to redirect_to("http://test.host/dashboard/user/searches/#{@user.get_search('').id}/gateway-payment/#{assigns(:receipt).receipt_id}" )
            end
          end
        end
      end
    end
  end

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

      it 'if receipt payment gateway service absent, redirects to dashboard' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:payment_gateway_service).and_return nil
        post :create, params: { receipt: receipt_params }
        receipt = Receipt.first
        expect(response.request.flash[:notice]).to eq("We couldn't redirect you to the payment gateway, please try again")
        expect(Receipt.first.status).to eq('failed')
        expect(response).to redirect_to(dashboard_path)
      end

      it 'if saving receipt is unsuccessful, render new' do
        receipt_params = FactoryBot.attributes_for(:receipt)
        Receipt.any_instance.stub(:save).and_return false
        Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
        post :create, params: { receipt: receipt_params }
        expect(response).to render_template('new')
      end
    end
  end
end
