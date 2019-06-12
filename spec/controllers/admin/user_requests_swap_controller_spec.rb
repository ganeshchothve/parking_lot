require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Admin::UserRequestsController, type: :controller do
  describe 'SWAP REQUEST' do
    before (:each) do
      create(:admin)
      @user = create(:user)
    end

    describe 'Conducted in Administration Level' do
      %w[superadmin admin crm].each do |user_role|
        context "Login By #{user_role} and " do
          before(:each) do
            @admin = create(user_role)
            allow_any_instance_of(Client).to receive(:enable_actual_inventory).and_return([user_role])
            sign_in_app(@admin)
          end

          %w[blocked booked_tentative booked_confirmed].each do |status|
            context "booking_detail is #{status.upcase}" do
              before(:each) do
                @booking_detail = book_project_unit(@user, nil, nil, status)
                @alternate_project_unit = create(:project_unit)
              end

              describe 'creates a request in pending state' do
                it ' booking_detail status must be updated to swap_requested' do
                  expect { post :create, params: { user_request_swap: { alternate_project_unit_id: @alternate_project_unit.id, requestable_id: @booking_detail.id, requestable_type: 'BookingDetail', event: 'pending' }, request_type: 'swap', user_id: @user.id } }.to change { UserRequest::Swap.count }.by(1)
                  expect(UserRequest.first.status).to eq('pending')
                  expect(@booking_detail.reload.status).to eq('swap_requested')
                end

                it 'Failed to create request' do
                  allow_any_instance_of(UserRequest).to receive(:save).and_return(false)
                  expect { post :create, params: { user_request_swap: { alternate_project_unit_id: @alternate_project_unit.id, requestable_id: @booking_detail.id, requestable_type: 'BookingDetail', event: 'pending' }, request_type: 'swap', user_id: @user.id } }.to change { UserRequest::Swap.count }.by(0)
                  expect(@booking_detail.reload.status).to eq(status)
                end
              end

              context "REJECTED by #{user_role}" do
                it "booking detail status changes to #{status}" do
                  user_request = create(:pending_user_request_swap, alternate_project_unit_id: @alternate_project_unit.id, user_id: @booking_detail.user_id, created_by_id: @admin.id, requestable_id: @booking_detail.id, requestable_type: 'BookingDetail', event: 'pending')
                  patch :update, params: { user_request_swap: { event: 'rejected', user_id: @user.id }, request_type: 'swap', id: user_request.id }
                  expect(@booking_detail.reload.status).to eq(status)
                  #expect(@booking_detail.project_unit.status).to eq('blocked')
                  expect(user_request.reload.status).to eq('rejected')
                  expect(@alternate_project_unit.reload.status).to eq('available')
                end

                it 'failed to reject' do
                  user_request = create(:pending_user_request_swap, alternate_project_unit_id: @alternate_project_unit.id, user_id: @booking_detail.user_id, created_by_id: @admin.id, requestable_id: @booking_detail.id, requestable_type: 'BookingDetail', event: 'pending')
                  allow_any_instance_of(UserRequest).to receive(:save).and_return(false)
                  patch :update, params: { user_request_swap: { event: 'rejected', user_id: @user.id }, request_type: 'swap', id: user_request.id }
                  expect(@booking_detail.reload.status).to eq('swap_requested')
                  expect(user_request.reload.status).to eq('pending')
                  expect(@alternate_project_unit.reload.status).to eq('available')
                end
              end

              context 'RESOLVED' do
                before(:each) do
                  @user_request = create(:pending_user_request_swap, alternate_project_unit_id: @alternate_project_unit.id, user_id: @booking_detail.user_id, created_by_id: @admin.id, requestable_id: @booking_detail.id, requestable_type: 'BookingDetail', event: 'pending')
                end

                it 'create one background process for swapping' do
                  expect{ patch :update, params: { user_request_swap: { event: 'processing', user_id: @user.id }, request_type: 'swap', id: @user_request.id } }.to change(UserRequests::BookingDetails::SwapProcess.jobs, :count).by(1)
                  expect(@booking_detail.reload.status).to eq('swapping')
                  expect(@user_request.reload.status).to eq('processing')
                end

                it 'no change in any object' do
                  allow_any_instance_of(UserRequest).to receive(:save).and_return(false)
                  expect{ patch :update, params: { user_request_swap: { event: 'processing', user_id: @user.id }, request_type: 'swap', id: @user_request.id } }.to change(UserRequests::BookingDetails::SwapProcess.jobs, :count).by(0)
                  expect(@booking_detail.reload.status).to eq('swap_requested')
                  expect(@user_request.reload.status).to eq('pending')
                end
              end

            end
          end
        end
      end
    end
  end
end
