require 'rails_helper'
RSpec.describe Buyer::UserRequestsController, type: :controller do
  describe 'buyer creates new swap request' do
    before (:each) do
      create(:admin)
      @user = create(:user)
      sign_in_app(@user)
    end

    %w[blocked booked_tentative booked_confirmed].each do |status|
      context "booking_detail is #{status.upcase}" do
        it 'Create request in pending state and booking_detail status must be swap_requested' do
          booking_detail = book_project_unit(@user)
          booking_detail.set(status: status)
          alternate_project_unit = create(:project_unit)
          user_request_params = { project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, booking_detail_id: booking_detail.id, event: 'pending' }
          expect { post :create, params: { user_request_swap: user_request_params, request_type: 'swap' } }.to change { UserRequest::Swap.count }.by(1)
          expect(UserRequest.first.status).to eq('pending')
          expect(booking_detail.reload.status).to eq('swap_requested')
        end
      end
    end
  end
end
