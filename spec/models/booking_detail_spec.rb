require 'rails_helper'
RSpec.describe BookingDetail, type: :model do
  describe 'booking detail controller states' do
    before(:each) do
      @client = create(:client)
      admin = create(:admin)
      # sign_in_app(admin)
      @user = create(:user)
      @booking_detail = book_project_unit(@user, nil, nil, 'hold')
      search = @booking_detail.search
      @project_unit = @booking_detail.project_unit
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      expect(@booking_detail.reload.status).to eq('scheme_approved')
    end

    it 'moves from under_negotiation to blocked when the booking detail scheme is approved and blocking amount is paid (receipt state is success)' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      expect(@booking_detail.reload.status).to eq('blocked')
    end
    it 'moves from under_negotiation to booked_tentative when the booking detail scheme is approved and amount paid is more than blocking amount(receipt state is success)' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: 40_000, status: 'clearance_pending')
      receipt1.success!
      expect(@booking_detail.reload.status).to eq('booked_tentative')
    end
    it 'moves from under_negotiation to blocked when the booking detail scheme is approved and more than blocking amount is paid (one receipt state is success and one is pending) ' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: 40_000)
      expect(@booking_detail.reload.status).to eq('blocked')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved and more than booking amount is paid (receipt state is success)' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @project_unit.booking_price, status: 'clearance_pending')
      receipt1.success!
      expect(@booking_detail.reload.status).to eq('booked_confirmed')
    end
  end
end
