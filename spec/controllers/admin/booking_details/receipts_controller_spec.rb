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

    it 'Receipt count will be increate by 1' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
      expect{ post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id } }.to change(Receipt, :count).by(1)
    end

    it 'selects default account when phase is missing or account is missing' do
      receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      receipt = assigns(:receipt)
      expect(receipt.account.by_default).to eq(true)
    end

    describe 'payment mode ONLINE' do
      it 'receipt saved successful' do
        receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
        post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
        receipt = assigns(:receipt)
        expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
        expect(response).to redirect_to("/dashboard/user/searches/#{@search.id}/gateway-payment/#{receipt.receipt_id}")
      end

      it 'if receipt account blank, render error message in flash' do
        Receipt.any_instance.stub(:account).and_return nil
        receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
        post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
        expect(response.request.flash[:alert]).to eq('Any Account is not linked yet. Please contact to admin.')
      end

      it 'receipt save fails' do
        Receipt.any_instance.stub(:save).and_return false
        Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
        receipt_params = FactoryBot.attributes_for(:receipt, payment_identifier: nil)
        post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
        expect(response).to render_template('new')
      end
    end

    describe 'payment mode' do
      context do
        %w[cheque rtgs neft imps card_swipe].each do |payment_mode|
          it "#{payment_mode} receipt saved successful" do
            receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
            post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
            receipt = assigns(:receipt)
            expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
            search_id = receipt.user.searches.desc(:created_at).first.id
            expect(response).to redirect_to(admin_user_receipts_url( @user, 'remote-state': assetables_path(assetable_type: receipt.class.model_name.i18n_key.to_s, assetable_id: receipt.id) ) )
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
