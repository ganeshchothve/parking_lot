require 'rails_helper'
RSpec.describe UserRequests::BookingDetails::CancellationProcess, type: :worker do
  describe 'User Booking' do
    before(:each) do
      @admin = create(:admin)
      @user = create(:user)
      @booking_detail = book_project_unit(@user, nil, nil)
      @user_request = create(:pending_user_request_cancellation, user_id: @booking_detail.user_id, created_by_id: @admin.id,requestable_id: @booking_detail.id, requestable_type: 'BookingDetail', event: 'pending')
      @user_request.set(status: 'processing', resolved_by_id: @admin.id)
      @booking_detail.set(status: 'cancelling')
    end

    describe 'UserRequest mark as Rejected' do
      context 'UserRequest is not in processing state wrong Id pass' do
        it 'ignore request, nothing will change' do
          expect( UserRequests::BookingDetails::CancellationProcess.new.perform('asddff') ).to eq(nil)
        end
      end
      context 'UserRequest is in processing state but booking_detail is missing' do
        it 'request put on Rejected state, with error message' do
          allow_any_instance_of(UserRequest).to receive(:requestable).and_return(nil)
          UserRequests::BookingDetails::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to include(I18n.t("worker.booking_details.errors.booking_cancellation_unavailable"))
        end
      end

      context 'UserRequest is in processing state but booking_detail is not in cancelling state' do
        it 'request put on Rejected state, with error message' do
          allow_any_instance_of(BookingDetail).to receive(:status).and_return(:hold)
          UserRequests::BookingDetails::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to include(I18n.t("worker.booking_details.errors.booking_cancellation_unavailable"))
        end
      end
    end

    describe 'UserRequest mark as cancelled' do
      context 'all receipts in success' do
        it 'request marked as resolved and booking is cancelled with all receipts as available for refund' do
          # allow(@user_request).to receive(:booking_detail).and_return(nil)
          UserRequests::BookingDetails::CancellationProcess.new.perform(@user_request.id)
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
          UserRequests::BookingDetails::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('cancelled')
          expect(@booking_detail.receipts.pluck(:status)).to eq(["cancelled"])
          expect(Receipt.count).to eq(2)
        end
      end

      context 'one receipt in clearance pending and one receipt on pending and one receipt in success' do
        it 'request marked as resolved, booking in resolved with (pending to cancelled) ( clearance pending to cancelled with new clearance pending) and (success to available for refund)' do
          _success = @booking_detail.receipts.first

          _clearance_pending = create(:check_payment, user_id: @user.id, total_amount: 30000, status: 'clearance_pending', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)

          _available_for_refund = create(:check_payment, user_id: @user.id, total_amount: 30000, status: 'available_for_refund', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)

          _pending = create(:check_payment, user_id: @user.id, total_amount: 20000, status: 'pending', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)
          _count = @booking_detail.receipts.clearance_pending.count
          expect(Receipt.count).to eq(4)
          UserRequests::BookingDetails::CancellationProcess.new.perform(@user_request.id)
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