require 'rails_helper'
RSpec.describe Buyer::BookingDetails::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    it 'selects not default account when there is a account linked to the phase' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)

      @booking_detail = book_project_unit(@user, nil, nil, 'hold')
      search = @booking_detail.search
      @project_unit = @booking_detail.project_unit

      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      receipt = Receipt.first
      receipt.success!
      expect(receipt.account.by_default).to eq(false)
    end
    it 'selects default account when there is no account linked to the phase' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)

      @booking_detail = book_project_unit(@user, nil, nil, 'hold')
      search = @booking_detail.search
      @project_unit = @booking_detail.project_unit

      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      receipt = Receipt.first
      receipt.success!
      receipt1 = Receipt.last
      receipt1.success!
      expect(Receipt.last.account.by_default).to eq(true)
    end
  end
end
