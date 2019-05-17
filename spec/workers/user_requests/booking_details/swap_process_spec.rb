require 'rails_helper'
RSpec.describe UserRequests::BookingDetails::SwapProcess, type: :worker do
  describe 'User Booking' do
    before(:each) do
      @admin = create(:admin)
      @user = create(:user)
      @user_request = swap_request(@user)
      @booking_detail = @user_request.requestable
      @alternate_project_unit = @user_request.alternate_project_unit
      @user_request.set(status: 'processing', resolved_by_id: @admin.id)
      @booking_detail.set(status: 'swapping')
    end

    describe 'UserRequest mark as Rejected' do
      context 'UserRequest is not in processing state wrong Id pass' do
        it 'ingore request, nothing will change' do
          expect( UserRequests::BookingDetails::SwapProcess.new.perform('asddff') ).to eq(nil)
        end
      end

      context 'UserRequest is in processing state but booking_detail is missing' do
        it 'request put on Rejected state, with error message' do
          allow_any_instance_of(UserRequest).to receive(:requestable).and_return(nil)
          UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to include('Booking Is not available for swapping.')
        end
      end

      context 'UserRequest is in processing state but alternative project unit is not available for booking.' do
        it 'request put on Rejected state, with error message' do
          @alternate_project_unit.set(status: 'blocked')
          UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@booking_detail.reload.status).to eq('blocked')
          expect(@user_request.reason_for_failure).to include('Alternative unit is not available for swapping.')
        end
      end

      context 'UserRequest is in processing state but booking_detail is not in swapping state' do
        it 'request put on Rejected state, with error message' do
          allow_any_instance_of(BookingDetail).to receive(:status).and_return(:hold)
          UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to include('Booking Is not available for swapping.')
        end
      end

      context 'UserRequest is in processing state but alternate_project_unit has higher blocking amount' do
        it 'request put in rejected state with error message' do
          allow_any_instance_of(ProjectUnit).to receive(:blocking_amount).and_return(100000)
          UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to include("Alternate Unit booking price is very high. No any receipt with minimum 100000.")
        end
      end
    end

    describe 'UserRequest mark as swapped' do
      context 'all receipts in success' do
        it 'request marked as resolved and booking is swapped with all receipts in cancelled and new new booking created with all receipts' do
          expect{ UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id) }.to change(BookingDetail, :count).by(1)
          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('swapped')
          expect(@booking_detail.receipts.pluck(:status)).to eq(["cancelled"])

          expect(@alternate_project_unit.reload.booking_detail.status).to eq('blocked')
          expect(@alternate_project_unit.reload.booking_detail.receipts.pluck(:status)).to eq(['success'])
          expect(@alternate_project_unit.reload.status).to eq('blocked')
        end
      end

      context 'all receipts in clearance pending' do
        it 'request marked as resolved and booking is swapped with all receipts cancelled with new receipts with same clearance pending for new booking' do
          @booking_detail.receipts.update_all(status: 'clearance_pending', tracking_id: nil, processed_on: nil)
          expect(Receipt.count).to eq(1)
          _count = @booking_detail.receipts.clearance_pending.count
          UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('swapped')
          expect(@booking_detail.receipts.pluck(:status)).to eq(["cancelled"])
          expect(Receipt.count).to eq(2)

          expect(@alternate_project_unit.reload.status).to eq('blocked')
          expect(@alternate_project_unit.booking_detail.status).to eq('blocked')
          expect(@alternate_project_unit.booking_detail.receipts.pluck(:status)).to eq(['clearance_pending'])
        end
      end

      context 'one receipt in clearance pending and one receipt on pending and one receipt in success' do
        it 'request marked as resolved, booking in resolved with (pending to cancelled) ( clearance pending to cancelled with new clearance pending) and (success to cancelled ) and create new booking_detail with only success clearance_pending ' do
          _success = @booking_detail.receipts.first

          _clearance_pending = create(:check_payment, user_id: @user.id, total_amount: 30000, status: 'clearance_pending', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)

          _available_for_refund = create(:check_payment, user_id: @user.id, total_amount: 30000, status: 'available_for_refund', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)

          _pending = create(:check_payment, user_id: @user.id, total_amount: 20000, status: 'pending', booking_detail_id: @booking_detail.id, tracking_id: nil, processed_on: nil)
          _count = @booking_detail.receipts.clearance_pending.count
          expect(Receipt.count).to eq(4)
          UserRequests::BookingDetails::SwapProcess.new.perform(@user_request.id)

          expect(@user_request.reload.status).to eq('resolved')
          expect(@booking_detail.reload.status).to eq('swapped')
          expect(_success.reload.status).to eq('cancelled')
          expect(_clearance_pending.reload.status).to eq('cancelled')
          expect(_available_for_refund.reload.status).to eq('available_for_refund')

          expect(@alternate_project_unit.reload.status).to eq('blocked')
          expect(@alternate_project_unit.booking_detail.status).to eq('booked_tentative')
          expect(@alternate_project_unit.booking_detail.receipts.pluck(:status).sort).to eq(['clearance_pending', 'success', 'pending'].sort)


          expect(@alternate_project_unit.booking_detail.receipts.count).to eq(3)
          expect(_pending.reload.status).to eq('cancelled')
        end
      end
    end
  end
end