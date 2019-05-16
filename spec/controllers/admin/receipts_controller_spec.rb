require 'rails_helper'
RSpec.describe Admin::ReceiptsController, type: :controller do
  describe '#create' do
    before(:each) do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      @not_default = create(:razorpay_payment, by_default: false)
      @not_default.phases << phase
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
    end

    describe '#lost_receipt' do
      describe 'creating' do
        before(:each) do
          superadmin = create(:superadmin)
          sign_in_app(superadmin)
        end

        it 'selects account which has been selected by the user(default false) and redirected to admin user index' do
          receipt_params = FactoryBot.attributes_for(:receipt)
          receipt_params[:payment_identifier] = 'rz1201'
          receipt_params[:account_number] = @not_default.id
          receipt_params[:payment_mode] = 'online'
          post :create, params: { receipt: receipt_params, user_id: @user.id }
          expect(Receipt.first.account.account_number).to eq(@not_default.account_number)
          expect(response).to redirect_to(admin_user_receipts_path(@user))
        end
      end

      describe 'rejecting' do
        %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner].each do |user_role|
          before(:each) do
            allow_any_instance_of(Client).to receive(:enable_channel_partners?).and_return(true)
            admin = create(user_role)
            sign_in_app(admin)
          end
          describe "User ROLE #{user_role}" do
            it 'does not permit account_number to be assigned to receipt' do
              receipt_params = FactoryBot.attributes_for(:receipt)
              receipt_params[:payment_identifier] = 'rz1201'
              receipt_params[:account_number] = @not_default.id
              receipt_params[:payment_mode] = 'online'
              expect { post :create, params: { receipt: receipt_params, user_id: @user.id } }.to change(Receipt, :count).by(0)
            end
          end
        end
      end
    end

    describe 'creating receipt' do
      %w[superadmin admin crm sales_admin sales cp_admin cp channel_partner].each do |user_role|
        describe "For #{user_role}" do
          before(:each) do
            allow_any_instance_of(Client).to receive(:enable_channel_partners?).and_return(true)
            admin = create(user_role)
            sign_in_app(admin)
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
            expect(response.request.flash[:alert]).to eq(I18n.t('admin.receipt_policy.create?.online_account_not_present', scope: "pundit"))
          end

          it 'send alert message when receipts is invalid' do
            receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil, total_amount: 0)
            post :create, params: { receipt: receipt_params, user_id: @user.id }
            expect(response.request.flash[:alert]).to eq(['Total Amount (Rs.) cannot be less than or equal to 0'])
          end

          describe 'payment is offline' do
            Receipt::OFFLINE_PAYMENT_MODE.each do |payment_mode|
              before(:each) do
                @receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: payment_mode)
              end

              it "redirects to users receipts index page when receipt payment_mode #{payment_mode}" do
                post :create, params: { receipt: @receipt_params, user_id: @user.id }
                expect(response).to redirect_to(admin_user_receipts_url(@user, 'remote-state': assetables_path(assetable_type: 'receipt', assetable_id: assigns(:receipt).id)))
              end
            end
          end

          describe 'payment_mode is online' do
            it 'redirects to payment link when receipt has no payment_identifier ' do
              receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
              post :create, params: { receipt: receipt_params, user_id: @user.id }
              expect(response).to redirect_to("http://test.host/dashboard/user/searches/#{@user.get_search('').id}/gateway-payment/#{assigns(:receipt).receipt_id}")
            end
          end
        end
      end
    end
  end

  describe 'payment mode ONLINE' do # TO DO ONLINE UPDATE
    before(:each) do
      default = create(:razorpay_payment, by_default: true)
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

    it 'redirects to searches controller payment_gateway function on successful save when payment_identifier is nil' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      receipt = Receipt.first
      search_id = receipt.user.searches.desc(:created_at).first.id
      expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
      expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
    end

    it 'if saving receipt is unsuccessful, render new' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_mode: 'online', payment_identifier: nil)
      Receipt.any_instance.stub(:save).and_return false
      Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
      post :create, params: { receipt: receipt_params, user_id: @user.id }
      expect(response).to render_template('new')
    end
  end

  describe 'payment mode' do
    before(:each) do
      create(:razorpay_payment, by_default: true)
    end

    context do
      %w[cheque rtgs neft imps card_swipe].each do |payment_mode|
        before(:each) do
          @client = create(:client)
          @admin = create(:admin)
          @user = create(:user)
          sign_in_app(@admin)
          kyc = create(:user_kyc, creator_id: @user.id, user: @user)
        end

        it "#{payment_mode} receipt created successfully" do
          receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
          post :create, params: { receipt: receipt_params, user_id: @user.id }
          receipt = assigns(:receipt)
          expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
          expect(response).to redirect_to(admin_user_receipts_url(@user, 'remote-state': assetables_path(assetable_type: receipt.class.model_name.i18n_key.to_s, assetable_id: receipt.id)))
        end

        it "#{payment_mode} receipt updated successfully" do
          receipt = create(:offline_payment, payment_mode: payment_mode, user_id: @user.id, total_amount: 50_000, status: 'clearance_pending')
          receipt_params = { event: 'success', tracking_id: '123211', processed_on: receipt.issued_date }
          patch :update, params: { receipt: receipt_params, user_id: @user.id, id: receipt.id }
          expect(response.request.flash[:notice]).to eq('Receipt was successfully updated.')
          expect(response).to redirect_to(admin_user_receipts_path(@user))
        end

        it "#{payment_mode} receipt update fails" do
          receipt = create(:offline_payment, payment_mode: payment_mode, user_id: @user.id, total_amount: 50_000, status: 'clearance_pending')
          receipt_params = { event: 'success', tracking_id: '123211', processed_on: Time.now - 1.day }
          Receipt.any_instance.stub(:save).and_return false
          patch :update, params: { receipt: receipt_params, user_id: @user.id, id: receipt.id }
          expect(response).to render_template('edit')
        end
      end
    end
  end

  describe "updating receipt" do
    
  end
end