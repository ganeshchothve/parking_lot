require 'rails_helper'
RSpec.describe Admin::BookingDetailsController, type: :controller do
  describe '.booking' do
    before (:each) do
      default = create(:razorpay_payment, by_default: true)
      @admin = create(:admin)
      @user = create(:user)
      sign_in_app(@admin)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @booking_detail = book_project_unit(@user)
      @project_unit = @booking_detail.project_unit
      @search = @booking_detail.search
    end

    it 'receipt is not present, redirect' do
      patch :booking, params: { id: @booking_detail.id, user_id: @user.id }
      expect(response).to redirect_to(new_admin_booking_detail_receipt_path(@booking_detail.user, @booking_detail))
      expect(response.request.flash[:notice]).to eq('Make new payment')
    end

    it 'online receipt saves successfully' do
      receipt = create(:receipt, payment_mode: 'online', user_id: @user.id, total_amount: 50_000, status: 'success')
      patch :booking, params: { id: @booking_detail.id, user_id: @user.id }
      expect(response).to redirect_to(admin_user_path(receipt.user))
      expect(response.request.flash[:notice]).to eq('You have completed the booking successfully.')
    end
  end

  describe do
    before (:each) do
      default = create(:razorpay_payment, by_default: true)
    end

    context do
      %w[cheque rtgs neft imps card_swipe].each do |payment_mode|
        before (:each) do
          @admin = create(:admin)
          @user = create(:user)
          sign_in_app(@admin)
          kyc = create(:user_kyc, creator_id: @user.id, user: @user)
          @booking_detail = book_project_unit(@user, nil, nil, 'hold')
          @search = @booking_detail.search
          @project_unit = @booking_detail.project_unit
        end

        it "#{payment_mode} receipt is present and saves successfully" do
          receipt = create(:offline_payment, payment_mode: payment_mode, user_id: @user.id, total_amount: 50_000, status: 'success', tracking_id: '123456', processed_on: Time.now - 1.day)
          patch :booking, params: { id: @booking_detail.id, user_id: @user.id }
          expect(response).to redirect_to(admin_user_path(receipt.user))
          expect(response.request.flash[:notice]).to eq('You have completed the booking successfully.')
        end

        it "#{payment_mode} receipt is present but does not save successfully" do
          receipt = create(:offline_payment, payment_mode: payment_mode, user_id: @user.id, total_amount: 50_000, status: 'success', tracking_id: '123456', processed_on: Time.now - 1.day)
          Receipt.any_instance.stub(:save).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
          patch :booking, params: { id: @booking_detail.id, user_id: @user.id }
          expect(response).to redirect_to(checkout_user_search_path(@booking_detail.search))
          expect(response.request.flash[:alert]).to eq(['Cheque Number / Transaction Identifier cannot be blank'])
        end
      end
    end
  end
end
