require 'rails_helper'
RSpec.describe UserRequests::CancellationProcess, type: :worker do
  describe 'User Booking' do
    before(:each) do
      @admin = create(:admin)
      @user = create(:user)
      @booking_detail = book_project_unit(@user, nil, nil)
      @user_request = create(:pending_user_request_cancellation, user_id: @booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: @booking_detail.id, event: 'pending')
      @user_request.set(status: 'processing', resolved_by_id: @admin.id)
      @booking_detail.set(status: 'cancelling')
    end

    describe 'UserRequest mark as cancelled' do
      context 'all receipts in success' do
        it 'request marked as resolved and booking is cancelled with all receipts as available for refund' do
          # allow(@user_request).to receive(:booking_detail).and_return(nil)
          UserRequests::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('cancelled')
          expect(@booking_detail.receipts.pluck(:status)).to eq(["available_for_refund"])
        end
      end

      context 'all receipts in clearance pending' do
        it 'request marked as resolved and booking is cancelled with all receipts cancelled with new receipts with same clearance pending' do
          @booking_detail.receipts.update_all(status: 'clearance_pending', tracking_id: nil, processed_on: nil)
          expect(Receipt.count).to eq(1)
          _count = @booking_detail.receipts.clearance_pending.count
          UserRequests::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('cancelled')
          expect(@booking_detail.receipts.pluck(:status)).to eq(["cancelled"])
          expect(Receipt.count).to eq(2)
        end
      end

      context 'one receipt in clearance pending and one receipt on pending and one receipt in success' do
        it 'request marked as resolved, booking in resolved with (pending to cancelled) ( clearance pending to cancelled with new clearance pending) and (success to available for refund)' do
          _success = @booking_detail.receipts.first

          _clearance_pending = create(:check_payment, user_id: @user.id, total_amount: 30000, project_unit_id: @booking_detail.project_unit_id, status: 'clearance_pending', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)

          _available_for_refund = create(:check_payment, user_id: @user.id, total_amount: 30000, project_unit_id: @booking_detail.project_unit_id, status: 'available_for_refund', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)

          _pending = create(:check_payment, user_id: @user.id, total_amount: 20000, project_unit_id: @booking_detail.project_unit_id, status: 'pending', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)
          _count = @booking_detail.receipts.clearance_pending.count
          expect(Receipt.count).to eq(4)
          UserRequests::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('cancelled')
          expect(_success.reload.status).to eq('available_for_refund')
          expect(_clearance_pending.reload.status).to eq('cancelled')
          expect(_available_for_refund.reload.status).to eq('available_for_refund')
          expect(_pending.reload.status).to eq('cancelled')
          expect(Receipt.count).to eq(5)
        end
      end
    end
  end
end