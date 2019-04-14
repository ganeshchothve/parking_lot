require 'rails_helper'
RSpec.describe Buyer::BookingDetailsController, type: :controller do
  describe 'booking detail controller states' do
    before(:each) do
      @client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit, available_for: 'user')
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      @search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: 'filter', results_count: nil, user_id: @user.id)
      @pubs = ProjectUnitBookingService.new(@project_unit)
      @booking_detail = @pubs.create_booking_detail @search.id
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      expect(@booking_detail.status).to eq('scheme_approved')
    end

    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.clearance_pending!
      expect(@booking_detail.reload.status).to eq('blocked')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.success!
      receipt1 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
      receipt1.clearance_pending!
      expect(@booking_detail.status).to eq('booked_tentative')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.clearance_pending!
      receipt1 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
      expect(@booking_detail.status).to eq('blocked')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
      receipt.clearance_pending!
      receipt1 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @project_unit.booking_price)
      receipt1.clearance_pending!
      expect(@booking_detail.status).to eq('booked_confirmed')
    end

    describe 'create receipt while booking' do
      it 'unattached blocking receipt present and save successful, receipt status success then redirect' do
        @receipt1 = create(:receipt, total_amount: 50_000, project_unit: nil, payment_mode: 'online', user: @booking_detail.user, status: 'success')
        patch :booking, params: { id: @booking_detail.id }
        expect(response).to redirect_to(buyer_user_path(@user))
      end

      it 'unattached blocking not present and save successful' do
        patch :booking, params: { id: @booking_detail.id }
        expect(response).to redirect_to("/dashboard/user/searches/#{@booking_detail.search.id}/gateway-payment/#{Receipt.first.receipt_id}")
      end

      it 'if save failed, redirect to checkout_user_search_path' do
        Receipt.any_instance.stub(:save).and_return false
        Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
        patch :booking, params: { id: @booking_detail.id }
        expect(response).to redirect_to(checkout_user_search_path(project_unit_id: @booking_detail.project_unit.id))
      end

      it 'if save successful, receipt status pending but payment_gateway service absent, set receipt status failed' do
        Receipt.any_instance.stub(:payment_gateway_service).and_return nil
        patch :booking, params: { id: @booking_detail.id }
        expect(Receipt.first.status).to eq('failed')
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
