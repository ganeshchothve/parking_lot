require 'rails_helper'
RSpec.describe Admin::UserRequestsController, type: :controller do
  describe 'booking detail status updated to' do
    before (:each) do
      phase = create(:phase)
      @admin = create(:admin)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      @user = create(:user)
      @kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @receipt = create(:receipt, user_id: @user.id)
      sign_in_app(@admin)
    end

    context 'resolved' do
      it 'successfully resolved and project unit made available' do
        @project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit3.id, user_id: @user.id, receipt_ids: [@receipt.id])
        @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit3.id, user_id: @user.id, created_by_id: @user.id)
        user_request_params = { status: 'resolved', user_id: @user.id }
        patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id }
        @booking_detail.reload
        @project_unit3.reload
        expect(@booking_detail.status).to eq('cancelled')
        expect(%w[available management employee].include?(@project_unit3.status))
      end

      it 'when receipt status changes from success to available_for_refund' do
        @receipt1 = create(:receipt, user_id: @user.id)
        @project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt1.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit3.id, user_id: @user.id, receipt_ids: [@receipt1.id])
        @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit3.id, user_id: @user.id, created_by_id: @user.id)
        user_request_params = { status: 'resolved', user_id: @user.id }
        patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id }
        @receipt1.reload
        @booking_detail.reload
        expect(@booking_detail.status).to eq('cancelled')
        expect(@receipt1.status).to eq('available_for_refund')
      end

      it 'when receipt status changes from clearance_pending to cancelled' do
        @receipt1 = create(:receipt, user_id: @user.id, status: 'clearance_pending')
        @project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt1.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit3.id, user_id: @user.id, receipt_ids: [@receipt1.id])
        @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit3.id, user_id: @user.id, created_by_id: @user.id)
        user_request_params = { status: 'resolved', user_id: @user.id }
        expect { patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id } }.to change { Receipt.count }.by(1)
        @receipt1.reload
        @booking_detail.reload
        expect(@booking_detail.status).to eq('cancelled')
        expect(@receipt1.status).to eq('cancelled')
      end

      it 'when receipt status is pending, project_unit set to nil' do
        @receipt1 = create(:receipt, user_id: @user.id, status: 'pending')
        @project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt1.id])
        @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit3.id, user_id: @user.id, receipt_ids: [@receipt1.id])
        @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit3.id, user_id: @user.id, created_by_id: @user.id)
        user_request_params = { status: 'resolved', user_id: @user.id }
        patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id }
        @receipt1.reload
        @booking_detail.reload
        expect(@booking_detail.status).to eq('cancelled')
        expect(@receipt1.project_unit.present?).to eq(false)
      end
    end

    it 'blocked when user_request rejected' do
      @project_unit1 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
      @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
      @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit1.id, user_id: @user.id, created_by_id: @user.id)
      user_request_params = { status: 'rejected', user_id: @user.id }
      patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id }
      expect(@project_unit1.booking_detail.status).to eq('blocked')
    end

    it 'booked_tentative when user_request rejected' do
      @project_unit1 = create(:project_unit, status: 'booked_tentative', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
      @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
      @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit1.id, user_id: @user.id, created_by_id: @user.id)
      user_request_params = { status: 'rejected', user_id: @user.id }
      patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id }
      expect(@project_unit1.booking_detail.status).to eq('blocked')
    end

    it 'booked_confirmed when user_request rejected' do
      @project_unit1 = create(:project_unit, status: 'booked_confirmed', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
      @booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: @project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
      @user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: @project_unit1.id, user_id: @user.id, created_by_id: @user.id)
      user_request_params = { status: 'rejected', user_id: @user.id }
      patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: @user_request.id }
      expect(@project_unit1.booking_detail.status).to eq('blocked')
    end
  end
end
