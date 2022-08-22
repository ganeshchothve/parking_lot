require 'rails_helper'
RSpec.describe Buyer::BookingDetailsController, type: :controller do
  describe 'booking detail controller states' do
    before(:each) do
      @client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      create(:razorpay_payment, by_default: true)
      sign_in_app(@user)
      @booking_detail = book_project_unit(@user, nil, nil, 'hold')
      @search = @booking_detail.search
      @project_unit = @booking_detail.project_unit
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      expect(@booking_detail.status).to eq('scheme_approved')
    end

    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.clearance_pending!
      expect(@booking_detail.reload.status).to eq('blocked')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: 40_000)
      receipt1.clearance_pending!
      expect(@booking_detail.status).to eq('booked_tentative')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.clearance_pending!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: 40_000)
      expect(@booking_detail.status).to eq('blocked')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.clearance_pending!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @project_unit.get_booking_price)
      receipt1.clearance_pending!
      expect(@booking_detail.status).to eq('booked_confirmed')
    end

    describe 'create receipt while booking' do
      it 'unattached blocking receipt present and save successful, receipt status success then redirect' do
        @receipt1 = create(:receipt, total_amount: 50_000, payment_mode: 'online', user: @booking_detail.user, status: 'success')
        patch :booking, params: { id: @booking_detail.id }
        expect(response).to redirect_to(buyer_user_path(@user))
      end

      it 'unattached blocking not present and save successful' do
        patch :booking, params: { id: @booking_detail.id }
        receipt = assigns(:receipt)
        expect(response).to redirect_to("/dashboard/user/searches/#{@booking_detail.search.id}/gateway-payment/#{receipt.receipt_id}")
      end

      it 'if save failed, redirect to checkout_user_search_path' do
        Receipt.any_instance.stub(:save).and_return false
        Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
        patch :booking, params: { id: @booking_detail.id }
        expect(response).to redirect_to(checkout_user_search_path(@search))
      end

      it 'if save successful, receipt status pending but payment_gateway service absent, set receipt status failed' do
        Receipt.any_instance.stub(:payment_gateway_service).and_return nil
        patch :booking, params: { id: @booking_detail.id }
        receipt = assigns(:receipt)
        expect(receipt.status).to eq('failed')
        expect(response.request.flash[:notice]).to eq("We couldn't redirect you to the payment gateway, please try again")
        expect(response).to redirect_to(dashboard_path)
      end

      it 'fails if user not confirmed' do
        @user.set(confirmed_at: nil)
        patch :booking, params: { id: @booking_detail.id }
        expect(response.request.flash[:alert]).to eq('You have to confirm your email address before continuing.')
      end

      it 'fails if user kyc not present' do
        @user.set(confirmed_at: nil)
        patch :booking, params: { id: @booking_detail.id }
        expect(response.request.flash[:alert].present?).to eq(true)
      end

      it 'fails if online account not present' do
        Buyer::ReceiptPolicy.any_instance.stub(:online_account_present?).and_return false
        patch :booking, params: { id: @booking_detail.id }
        expect(response.request.flash[:alert].present?).to eq(true)
      end
    end
  end
end
