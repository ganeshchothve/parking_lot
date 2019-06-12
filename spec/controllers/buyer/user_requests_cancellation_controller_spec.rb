require 'rails_helper'
RSpec.describe Buyer::UserRequestsController, type: :controller do
  describe 'New cancellation request is created' do
    before (:each) do
      create(:admin)
      @user = create(:user)
      sign_in_app(@user)
    end

    context 'by buyer when ' do
      %w[blocked booked_tentative booked_confirmed].each do |status|
        context "booking_detail is #{status.upcase} " do
          it 'user request status changes to pending and booking_detail status changes to cancellation_requested' do
            booking_detail = book_project_unit(@user)
            booking_detail.set(status: status)
            user_request_params = { user_id: @user.id, requestable_id: booking_detail.id, requestable_type: 'BookingDetail', event: 'pending' }
            expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest::Cancellation.count }.by(1)
            expect(UserRequest.first.status).to eq('pending')
            expect(booking_detail.reload.status).to eq('cancellation_requested')
          end
        end
      end

      describe "receipt is success " do
        it " create user_request for cancellation in pending state and receipt status changes to cancellation_requested " do 
          receipt = create(:receipt, payment_mode: 'online', user_id: @user.id, total_amount: 50_000, status: 'success')
          user_request_params = { user_id: @user.id, requestable_id: receipt.id, requestable_type: 'Receipt', event: 'pending' }
          expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest::Cancellation.count }.by(1)
          expect(UserRequest.first.status).to eq('pending')
          expect(receipt.reload.status).to eq('cancellation_requested')
        end
      end
    end
  end
end
