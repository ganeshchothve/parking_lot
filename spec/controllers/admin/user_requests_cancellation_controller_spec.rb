require 'rails_helper'

RSpec.describe Admin::UserRequestsController, type: :controller do
  describe 'CANCELLATION REQUEST' do
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

            context "booking_detail is #{status.upcase} then " do
              before(:each) do
                @booking_detail = book_project_unit(@user, nil, nil, status)
              end

              describe 'Create New User Request in pending state ' do
                it 'and booking_detail status changed to cancellation requested' do
                  expect { post :create, params: { user_request_cancellation: { user_id: @user.id, booking_detail_id: @booking_detail.id, event: 'pending' }, request_type: 'cancellation', user_id: @user.id } }.to change { UserRequest::Cancellation.count }.by(1)
                  expect(UserRequest.first.status).to eq('pending')
                  expect(@booking_detail.reload.status).to eq('cancellation_requested')
                end

                it 'Failed to create request' do
                  allow_any_instance_of(UserRequest).to receive(:save).and_return(false)
                  expect { post :create, params: { user_request_cancellation: { user_id: @user.id, booking_detail_id: @booking_detail.id, event: 'pending' }, request_type: 'cancellation', user_id: @user.id } }.to change { UserRequest::Cancellation.count }.by(0)
                  expect(@booking_detail.reload.status).to eq(status)
                end
              end

              context "REJECTED by #{user_role}" do
                it 'booking detail status changes to blocked' do
                  user_request = create(:pending_user_request_cancellation, user_id: @booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: @booking_detail.id, event: 'pending')
                  user_request_params = { event: 'rejected', user_id: @user.id }
                  patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
                  expect(@booking_detail.reload.status).to eq(status)
                  expect(user_request.reload.status).to eq('rejected')
                end

                it 'failed to reject' do
                  user_request = create(:pending_user_request_cancellation, user_id: @booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: @booking_detail.id, event: 'pending')
                  user_request_params = { event: 'rejected', user_id: @user.id }
                  patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
                  expect(@booking_detail.reload.status).to eq(status)
                  expect(user_request.reload.status).to eq('rejected')
                end
              end

              context "RESOLVED by #{user_role}" do
                before(:each) do
                  @user_request = create(:pending_user_request_cancellation, user_id: @booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: @booking_detail.id, event: 'pending')
                end
                it 'create one background process for cancellation' do
                  expect{ patch :update, params: { user_request_cancellation: { event: 'processing', user_id: @user.id }, request_type: 'cancellation', id: @user_request.id } }.to change(UserRequests::CancellationProcess.jobs, :count).by(1)
                  expect(@booking_detail.reload.status).to eq('cancelling')
                  expect(@user_request.reload.status).to eq('processing')
                end

                it 'no change in any object' do
                  allow_any_instance_of(UserRequest).to receive(:save).and_return(false)
                  expect{ patch :update, params: { user_request_cancellation: { event: 'processing', user_id: @user.id }, request_type: 'cancellation', id: @user_request.id } }.to change(UserRequests::CancellationProcess.jobs, :count).by(0)
                  expect(@booking_detail.reload.status).to eq('cancellation_requested')
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
