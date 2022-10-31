require 'rails_helper'
RSpec.describe Admin::BookingDetails::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    before(:each) do
      @admin = create(:admin)
      @user = create(:user)
      create(:phase)
      create(:razorpay_payment, by_default: true)
      create(:razorpay_payment, by_default: false)
      @booking_detail = book_project_unit(@user)
      @project_unit = @booking_detail.project_unit
      @search = @booking_detail.search
      sign_in_app(@admin)
    end

    it 'receipt saved successful' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      receipt = assigns(:receipt)
      expect(response.request.flash[:notice]).to eq(I18n.t("controller.receipts.notice.receipt_updated"))
      search_id = receipt.user.searches.desc(:created_at).first.id
      expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
    end

    it 'Receipt count will be increase by 1' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
      expect { post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id } }.to change(Receipt, :count).by(1)
    end

    it 'selects default account when phase is missing or account is missing' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      receipt = assigns(:receipt)
      expect(receipt.account.by_default).to eq(true)
    end

    describe 'payment mode ONLINE' do

      context "when kyc is not present" do
        it "when enable_booking_without_kyc is true" do
          Client.first.set({enable_booking_without_kyc: true,enable_payment_without_kyc: false})
          receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
          @booking_detail = booking_without_kyc(@user)
          allow_any_instance_of(User).to receive(:user_kyc_ids).and_return([])
          expect{post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }}.to change(Receipt, :count).by(1)
        end

        it "when enable_booking_without_kyc is false" do
          Client.first.set({enable_booking_without_kyc: false,enable_payment_without_kyc: true})
          receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
          @booking_detail = booking_without_kyc(@user)
          allow_any_instance_of(User).to receive(:user_kyc_ids).and_return([])
          expect{post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }}.to change(Receipt, :count).by(0)
        end
      end
      it 'receipt saved successful' do
        receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
        post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
        receipt = assigns(:receipt)
        expect(response.request.flash[:notice]).to eq(I18n.t("controller.receipts.notice.receipt_updated"))
        expect(response).to redirect_to("/dashboard/user/searches/#{@search.id}/gateway-payment/#{receipt.receipt_id}")
      end
    end

    describe 'payment mode' do
      context do
        %w[cheque rtgs neft imps card_swipe].each do |payment_mode|

        context "when kyc is not present" do
          it "when enable_booking_without_kyc is true" do
            Client.first.set({enable_booking_without_kyc: true,enable_payment_without_kyc: false})
            receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
            @booking_detail = booking_without_kyc(@user)
            allow_any_instance_of(User).to receive(:user_kyc_ids).and_return([])
            expect{post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }}.to change(Receipt, :count).by(1)
            
          end

          it "when enable_booking_without_kyc is false" do 
            Client.first.set({enable_booking_without_kyc: false,enable_payment_without_kyc: true})
            receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
            @booking_detail = booking_without_kyc(@user)
            allow_any_instance_of(User).to receive(:user_kyc_ids).and_return([])
            expect{post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }}.to change(Receipt, :count).by(0)
          end
        end

          it "#{payment_mode} receipt saved successful" do
            receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
            post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
            receipt = assigns(:receipt)
            expect(response.request.flash[:notice]).to eq(I18n.t("controller.receipts.notice.receipt_updated"))
            search_id = receipt.user.searches.desc(:created_at).first.id
            expect(response).to redirect_to(admin_user_receipts_url(@user, 'remote-state': assetables_path(assetable_type: receipt.class.model_name.i18n_key.to_s, assetable_id: receipt.id)))
          end

          it "#{payment_mode} receipt save fails" do
            Receipt.any_instance.stub(:save).and_return false
            Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
            receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
            post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
            expect(response).to render_template('new')
          end
        end
      end
    end
  end
end
