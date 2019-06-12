require 'rails_helper'
RSpec.describe Buyer::BookingDetails::ReceiptsController, type: :controller do
  describe 'create receipt' do
    before(:each) do
      default = create(:razorpay_payment, by_default: true)
      admin = create(:admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      sign_in_app(@user)
      @booking_detail = book_project_unit(@user, nil, nil, 'hold')
      @search = @booking_detail.search
      @project_unit = @booking_detail.project_unit
    end

    it 'when receipt successfully saves and payment gateway service is present, redirect' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user_id, booking_detail_id: @booking_detail.id }
      receipt = Receipt.first
      search_id = receipt.user.searches.desc(:created_at).first.id
      expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
    end

    it 'when receipt successfully saves and payment gateway service is absent, update status to failed' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      Receipt.any_instance.stub(:payment_gateway_service).and_return nil
      post :create, params: { receipt: receipt_params, user_id: @user_id, booking_detail_id: @booking_detail.id }
      expect(response.request.flash[:notice]).to eq("We couldn't redirect you to the payment gateway, please try again")
      expect(Receipt.first.status).to eq('failed')
      expect(response).to redirect_to(dashboard_path)
    end

    it 'when receipt fails to save' do
      receipt_params = FactoryBot.attributes_for(:receipt)
      Receipt.any_instance.stub(:save).and_return false
      Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
      post :create, params: { receipt: receipt_params, user_id: @user_id, booking_detail_id: @booking_detail.id }
      expect(response).to render_template('new')
    end
  end
end
