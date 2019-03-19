require 'rails_helper'
require 'sidekiq/testing'
# Sidekiq::Testing.fake!
# Sidekiq::Testing.inline!
# Sidekiq::Testing.disable!

RSpec.describe Admin::UserRequestsController, type: :controller do
  describe 'booking detail status updated to' do
    before (:each) do
      @admin = create(:admin)
      @user = create(:user)
      sign_in_app(@admin)
      Sidekiq::Testing.inline!
    end

    context 'when admin creates a user request for cancellation' do
      %w[blocked booked_tentative booked_confirmed].each do |status|
        context "booking_detail is #{status.upcase} then " do
          it 'Create new user request with pending state and booking_detail must be in cancellation_requested' do
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
        %w[blocked booked_tentative booked_confirmed].each do |status|
          it 'blocked when user_request rejected' do
            Sidekiq::Testing.disable!
            booking_detail = book_project_unit(@user)
            booking_detail.set(status: status)
            user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
            user_request_params = { event: 'rejected', user_id: @user.id }
            patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
            expect(booking_detail.reload.status).to eq('blocked')
            # expect(user_request.reload.status).to eq('rejected')
          end
        end
      end

      context 'RESOLVED' do
        it 'successfully, receipt status changes from success to available_for_refund and project unit is made available' do
          booking_detail = book_project_unit(@user)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(booking_detail.reload.status).to eq('cancelled')
          expect(booking_detail.receipts.first.reload.status).to eq('available_for_refund')
          expect(%w[available management employee].include?(booking_detail.project_unit.status))
          expect(user_request.reload.status).to eq('resolved')
        end

        it 'when receipt status changes from clearance_pending to cancelled' do
          receipt = create(:receipt, user_id: @user.id, total_amount: 50_000, status: 'clearance_pending')
          booking_detail = book_project_unit(@user, nil, receipt)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          expect { patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id } }.to change { Receipt.count }.by(1)
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(booking_detail.reload.status).to eq('cancelled')
          expect(%w[available management employee].include?(booking_detail.project_unit.status))
          expect(receipt.reload.status).to eq('cancelled')
          expect(Receipt.last.status).to eq('clearance_pending')
          expect(user_request.reload.status).to eq('resolved')
        end

        it 'when receipt status is pending, project_unit set to nil' do
          receipt = create(:receipt, user_id: @user.id, total_amount: 50_000, status: 'pending')
          booking_detail = book_project_unit(@user, nil, receipt)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(booking_detail.reload.status).to eq('cancelled')
          expect(%w[available management employee].include?(booking_detail.project_unit.status))
          expect(receipt.reload.project_unit.present?).to eq(false)
          expect(user_request.reload.status).to eq('resolved')
        end
      end
    end

    describe 'rejected when processing and processing fails' do
      context 'receipt reverted' do
        it 'when receipt success -> available_for_refund -> success' do
          booking_detail = book_project_unit(@user)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          Receipt.any_instance.stub(:available_for_refund!).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(booking_detail.receipts.first.reload.status).to eq('success')
          # expect(user_request.reload.status).to eq('rejected')
          expect(booking_detail.reload.status).to eq('blocked')
        end

        it 'when receipt clearance_pending -> cancelled -> clearance_pending' do
          receipt = create(:receipt, user_id: @user.id, total_amount: 30_000, status: 'clearance_pending')
          booking_detail = book_project_unit(@user, nil, receipt)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          count = Receipt.count
          Receipt.any_instance.stub(:cancel!).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(receipt.reload.status).to eq('clearance_pending')
          # expect(user_request.reload.status).to eq('rejected')
          expect(booking_detail.reload.status).to eq('blocked')
          expect(Receipt.count).to eq(count)
        end

        it 'when receipt clearance_pending, dup receipt fails' do
          receipt = create(:receipt, user_id: @user.id, total_amount: 30_000, status: 'clearance_pending')
          booking_detail = book_project_unit(@user, nil, receipt)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          count = Receipt.count
          Receipt.any_instance.stub(:cancel!).and_return true
          Receipt.any_instance.stub(:save).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          expect(receipt.reload.status).to eq('clearance_pending')
          # expect(user_request.reload.status).to eq('rejected')
          expect(booking_detail.reload.status).to eq('blocked')
          expect(Receipt.count).to eq(count)
        end

        it 'when receipt pending, project unit nil reverted' do
          receipt = create(:receipt, user_id: @user.id, total_amount: 50_000, status: 'pending')
          booking_detail = book_project_unit(@user, nil, receipt)
          user_request = create(:pending_user_request_cancellation, project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          Receipt.any_instance.stub(:save).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_mode, 'cannot be nil') })
          patch :update, params: { user_request_cancellation: user_request_params, request_type: 'cancellation', id: user_request.id }
          expect(receipt.reload.status).to eq('pending')
          expect(receipt.project_unit.reload.present?).to eq(true)
          # expect(user_request.reload.status).to eq('rejected')
          expect(booking_detail.reload.status).to eq('blocked')
        end
      end
    end
  end
end
