require 'rails_helper'
RSpec.describe Admin::UserRequestsController, type: :controller do
  describe 'booking detail status updated to' do
    before (:each) do
      @admin = create(:admin)
      @user = create(:user)
      sign_in_app(@admin)
    end

    context 'when admin create as a user request for cancellation' do
      %w(blocked booked_tentative booked_confirmed).each do |status|
        context "booking_detail in #{ status.upcase } then " do
          it 'Create new user request with pending statue and booking_detail must be in cancellation_requested' do
            booking_detail = book_project_unit(@user)
            booking_detail.set(status: status)
            user_request_params = { project_unit_id: booking_detail.project_unit_id, user_id: @user.id, booking_detail_id: booking_detail.id, event: 'pending' }
            expect { post :create, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', user_id: @user.id } }.to change { UserRequest::Cancellation.count }.by(1)
            expect(UserRequest.first.status).to eq('pending')
            expect(booking_detail.reload.status).to eq('cancellation_requested')
          end
        end
      end
    end

    context 'User request rejected by admin' do
      context 'REJECTED' do
        it 'blocked when user_request rejected' do
          booking_detail = book_project_unit(@user)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'rejected', user_id: @user.id }
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          expect(booking_detail.reload.status).to eq('blocked')
        end
      end

      context 'RESOLVED' do
        it 'successfully and project unit made available' do
          booking_detail = book_project_unit(@user)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')

          user_request_params = { event: 'processing', user_id: @user.id }
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }

          expect(booking_detail.reload.status).to eq('cancelled')
          expect(%w[available management employee].include?(booking_detail.project_unit.status))
        end

        it 'when receipt status changes from success to available_for_refund' do
          receipt1 = create(:receipt, user_id: @user.id)
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [receipt1.id])
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt1.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          receipt1.reload
          booking_detail.reload
          expect(booking_detail.status).to eq('cancelled')
          expect(receipt1.status).to eq('available_for_refund')
        end

        it 'when receipt status changes from clearance_pending to cancelled' do
          receipt1 = create(:receipt, user_id: @user.id, status: 'clearance_pending')
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [receipt1.id])
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt1.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          expect { patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id } }.to change { Receipt.count }.by(1)
          receipt1.reload
          booking_detail.reload
          expect(booking_detail.status).to eq('cancelled')
          expect(receipt1.status).to eq('cancelled')
        end

        it 'when receipt status is pending, project_unit set to nil' do
          receipt1 = create(:receipt, user_id: @user.id, status: 'pending')
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [receipt1.id])
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt1.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          receipt1.reload
          booking_detail.reload
          expect(booking_detail.status).to eq('cancelled')
          expect(receipt1.project_unit.present?).to eq(false)
        end
      end


    end

    describe 'rejected when processing and processing fails' do
      context 'receipt reverted' do
        it 'when receipt success -> available_for_refund -> success' do
          receipt1 = create(:receipt, user_id: @user.id)
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [receipt1.id])
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt1.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          Receipt.any_instance.stub(:available_for_refund!).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          user_request.reload
          receipt1.reload
          booking_detail.reload
          expect(receipt1.status).to eq('success')
          expect(user_request.status).to eq('rejected')
          expect(booking_detail.status).to eq('blocked')
        end

        it 'when receipt clearance_pending -> cancelled -> clearance_pending' do
          receipt1 = create(:receipt, user_id: @user.id, status: 'clearance_pending')
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id)
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt1.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          receipt1.set(project_unit_id: project_unit3.id)
          count = Receipt.count
          Receipt.any_instance.stub(:cancel!).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          receipt1.reload
          booking_detail.reload
          user_request.reload
          expect(receipt1.status).to eq('clearance_pending')
          expect(user_request.status).to eq('rejected')
          expect(booking_detail.status).to eq('blocked')
          expect(Receipt.count).to eq(count)
        end

        it 'when receipt clearance_pending, dup receipt fails' do
          receipt2 = create(:receipt, user_id: @user.id, status: 'clearance_pending')
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id)
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt2.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          receipt2.set(project_unit_id: project_unit3.id)
          count = Receipt.count
          Receipt.any_instance.stub(:cancel!).and_return true
          Receipt.any_instance.stub(:save).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          receipt2.reload
          booking_detail.reload
          user_request.reload
          expect(receipt2.status).to eq('clearance_pending')
          expect(user_request.status).to eq('rejected')
          expect(booking_detail.status).to eq('blocked')
          expect(Receipt.count).to eq(count)
        end

        it 'when receipt pending, project unit nil reverted' do
          receipt3 = create(:receipt, user_id: @user.id, status: 'pending')
          project_unit3 = create(:project_unit, status: 'blocked', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [receipt3.id])
          booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit3.id, user_id: @user.id, receipt_ids: [receipt3.id])
          user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit3.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
          user_request_params = { event: 'processing', user_id: @user.id }
          Receipt.any_instance.stub(:save).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          receipt3.reload
          booking_detail.reload
          project_unit3.reload
          user_request.reload
          expect(receipt3.status).to eq('pending')
          expect(receipt3.project_unit.present?).to eq(true)
          expect(user_request.status).to eq('rejected')
          expect(booking_detail.status).to eq('blocked')
        end
      end
    end

    it 'booked_tentative when user_request rejected' do
      project_unit1 = create(:project_unit, status: 'booked_tentative', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
      booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
      user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit1.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
      user_request_params = { event: 'rejected', user_id: @user.id }
      patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
      expect(project_unit1.booking_detail.status).to eq('blocked')
    end

    it 'booked_confirmed when user_request rejected' do
      project_unit1 = create(:project_unit, status: 'booked_confirmed', user_id: @user.id, primary_user_kyc_id: @kyc.id, receipt_ids: [@receipt.id])
      booking_detail = BookingDetail.create(primary_user_kyc_id: @kyc.id, status: 'cancellation_requested', project_unit_id: project_unit1.id, user_id: @user.id, receipt_ids: [@receipt.id])
      user_request = UserRequest::Cancellation.create(status: 'pending', project_unit_id: project_unit1.id, user_id: @user.id, created_by_id: @user.id, booking_detail_id: booking_detail.id)
      user_request_params = { event: 'rejected', user_id: @user.id }
      patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
      expect(project_unit1.booking_detail.status).to eq('blocked')
    end
  end
end
