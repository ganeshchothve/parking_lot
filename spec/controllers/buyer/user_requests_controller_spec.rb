require 'rails_helper'
RSpec.describe Buyer::UserRequestsController, type: :controller do
  describe 'new user request created' do
    before (:each) do
      phase = create(:phase)
      admin = create(:admin)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      @user = create(:user)
      @kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @receipt = create(:receipt, user_id: @user.id)
      sign_in_app(@user)
    end

    it 'status set to pending' do
      @project_unit1 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
      @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: @project_unit1.status, project_unit_id: @project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
      user_request_params = { project_unit_id: @project_unit1.id, user_id: @user.id, created_by_id: @user_id, booking_detail_id: @booking_detail.id }
      expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest.count }.by(1)
      expect(UserRequest.first.status).to eq('pending')
    end

    context 'booking detail status changes to cancellation_requested' do
      it 'when project unit status blocked' do
        @project_unit1 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: @project_unit1.status, project_unit_id: @project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
        user_request_params = { event: 'pending', project_unit_id: @project_unit1.id, user_id: @user.id, created_by_id: @user_id, booking_detail_id: @booking_detail.id }
        expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest.count }.by(1)
        @booking_detail.reload
        expect(@booking_detail.status).to eq('cancellation_requested')
      end

      it 'when project unit status booked_tentative' do
        @project_unit2 = create(:project_unit, status: 'booked_tentative', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: @project_unit2.status, project_unit_id: @project_unit2.id, user_id: @user.id, receipt_ids: [@receipt.id])
        user_request_params = { event: 'pending', project_unit_id: @project_unit2.id, user_id: @user.id, resolved_by_id: nil, created_by_id: @user_id, booking_detail_id: @booking_detail.id }
        expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest.count }.by(1)
        @booking_detail.reload
        expect(@booking_detail.status).to eq('cancellation_requested')
      end

      it 'when project unit status booked_confirmed' do
        @project_unit3 = create(:project_unit, status: 'booked_confirmed', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: @project_unit3.status, project_unit_id: @project_unit3.id, user_id: @user.id, receipt_ids: [@receipt.id])
        user_request_params = { event: 'pending', resolved_at: nil, reason_for_failure: nil, project_unit_id: @project_unit3.id, user_id: @user.id, resolved_by_id: nil, created_by_id: @user_id, booking_detail_id: @booking_detail.id }
        expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation' } }.to change { UserRequest.count }.by(1)
        @booking_detail.reload
        expect(@booking_detail.status).to eq('cancellation_requested')
      end
    end
  end
end
