require 'rails_helper'
RSpec.describe Buyer::UserRequestsController, type: :controller do
  describe 'new user request created' do
    before (:each) do
      create(:admin)
      @user = create(:user)
      sign_in_app(@user)
    end

    context 'when buyer create a user request cancellation' do
      %w[blocked booked_tentative booked_confirmed].each do |status|
        context "booking_detail in #{status.upcase} then " do
          it 'Create new user request with pending state and booking_detail must be in cancellation_requested' do
            booking_detail = book_project_unit(@user)
            booking_detail.set(status: status)
            user_request_params = { project_unit_id: booking_detail.project_unit_id, user_id: @user.id, booking_detail_id: booking_detail.id, event: 'pending' }
            expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest::Cancellation.count }.by(1)
            expect(UserRequest.first.status).to eq('pending')
            expect(booking_detail.reload.status).to eq('cancellation_requested')
          end
        end
      end
    end
  end
end
