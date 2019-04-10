require 'rails_helper'
RSpec.describe Buyer::BookingDetailsController, type: :controller do
  describe 'booking detail controller states' do
    before(:each) do
      @client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: 'filter', results_count: nil, user_id: @user.id)
      @pubs = ProjectUnitBookingService.new(@project_unit)
      @booking_detail = @pubs.create_booking_detail search.id
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
  end
end
