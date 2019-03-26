require 'rails_helper'
require 'sidekiq/testing'
# Sidekiq::Testing.fake!
# Sidekiq::Testing.inline!
# Sidekiq::Testing.disable!

RSpec.describe Admin::UserRequestsController, type: :controller do
  describe 'SWAP REQUEST' do
    before (:each) do
      @admin = create(:admin)
      @user = create(:user)
      @scheme = scheme
      sign_in_app(@admin)
      Sidekiq::Testing.inline!
    end

    %w[blocked booked_tentative booked_confirmed].each do |status|
      context "booking_detail is #{status.upcase}" do
        it 'admin creates a user request in pending state and booking_detail status must be updated to swap_requested' do
          booking_detail = book_project_unit(@user)
          booking_detail.set(status: status)
          alternate_project_unit = create(:project_unit)
          user_request_params = { project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, booking_detail_id: booking_detail.id, event: 'pending' }
          expect { post :create, params: { user_request_swap: user_request_params, request_type: 'swap', user_id: @user.id } }.to change { UserRequest::Swap.count }.by(1)
          expect(UserRequest.first.status).to eq('pending')
          expect(booking_detail.reload.status).to eq('swap_requested')
        end
      end
    end

    context 'REJECTED' do
      %w[blocked booked_tentative booked_confirmed].each do |status|
        it 'by admin and booking detail blocked' do
          Sidekiq::Testing.disable!
          booking_detail = book_project_unit(@user)
          booking_detail.set(status: status)
          alternate_project_unit = create(:project_unit)
          user_request = create(:pending_user_request_swap, project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'rejected', user_id: @user.id }
          patch :update, params: { user_request_swap: user_request_params, request_type: 'swap', id: user_request.id }
          expect(booking_detail.reload.status).to eq('blocked')
          expect(booking_detail.reload.project_unit.status).to eq('blocked')
          expect(user_request.reload.status).to eq('rejected')
          expect(alternate_project_unit.reload.status).to eq('available')
        end
      end
    end

    context 'RESOLVED' do
      it 'successfully, current project unit is made available, current booking detail status changes to swapped, alternate project unit and booking detail status is blocked' do
        booking_detail = book_project_unit(@user)
        booking_detail_scheme = create(:booking_detail_scheme, derived_from_scheme_id: @scheme.id, booking_detail: booking_detail, status: 'approved', project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id)
        alternate_project_unit = create(:project_unit)
        user_request = create(:pending_user_request_swap, project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
        user_request_params = { event: 'processing', user_id: @user.id }
        count = BookingDetailScheme.count
        expect { patch :update, params: { user_request_swap: user_request_params, request_type: 'swap', id: user_request.id } }.to change { BookingDetail.count }.by(1)
        # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
        expect(user_request.reload.status).to eq('resolved')
        expect(booking_detail.reload.status).to eq('swapped')
        expect(booking_detail.reload.project_unit.status).to eq('available')
        expect(alternate_project_unit.reload.status).to eq('blocked')
        expect(BookingDetail.first.status).to eq('blocked')
        expect(BookingDetailScheme.count).to eq(count + 1)
        expect(BookingDetailScheme.last.booking_detail).to eq(BookingDetail.first)
      end

      context 'successfully, receipt status is ' do
        it 'changed from success or clearance pending or pending to cancelled ' do
          booking_detail = book_project_unit(@user)
          %w[clearance_pending pending].each do |status|
            booking_detail.receipts << create(:receipt, user_id: @user.id, total_amount: 30_000, status: status)
          end
          booking_detail_scheme = create(:booking_detail_scheme, derived_from_scheme_id: @scheme.id, booking_detail: booking_detail, status: 'approved', project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id)
          alternate_project_unit = create(:project_unit)
          user_request = create(:pending_user_request_swap, project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          expect { patch :update, params: { user_request_swap: user_request_params, request_type: 'swap', id: user_request.id } }.to change { Receipt.count }.by(3)
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(user_request.reload.status).to eq('resolved')
          expect(booking_detail.reload.status).to eq('swapped')
          booking_detail.receipts.each do |receipt|
            expect(receipt.status).to eq('cancelled')
          end
        end

        it 'the same(failed or available_for_refund or refunded or cancelled)' do
          booking_detail = book_project_unit(@user)
          %w[failed available_for_refund refunded cancelled].each do |status|
            booking_detail.receipts << create(:receipt, user_id: @user.id, total_amount: 30_000, status: status)
          end
          booking_detail_scheme = create(:booking_detail_scheme, derived_from_scheme_id: @scheme.id, booking_detail: booking_detail, status: 'approved', project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id)
          alternate_project_unit = create(:project_unit)
          user_request = create(:pending_user_request_swap, project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
          user_request_params = { event: 'processing', user_id: @user.id }
          expect { patch :update, params: { user_request_swap: user_request_params, request_type: 'swap', id: user_request.id } }.to change { Receipt.count }.by(1)
          # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
          expect(user_request.reload.status).to eq('resolved')
          expect(booking_detail.reload.status).to eq('swapped')
          booking_detail.receipts.each do |receipt|
            expect(%w[failed available_for_refund refunded cancelled].include?(receipt.status)).to eq(true)
          end
        end
      end
    end

    context 'REJECTED due to internal error' do
      it 'creation of new booking detail scheme failed, user_request rejected, booking detail changes to blocked' do
        booking_detail = book_project_unit(@user)
        booking_detail_scheme = create(:booking_detail_scheme, derived_from_scheme_id: @scheme.id, booking_detail: booking_detail, status: 'approved', project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id)
        alternate_project_unit = create(:project_unit)
        user_request = create(:pending_user_request_swap, project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
        user_request_params = { event: 'processing', user_id: @user.id }
        BookingDetailScheme.any_instance.stub(:save).and_return false
        BookingDetailScheme.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(BookingDetailScheme.new).tap { |e| e.add(:project_unit, 'cannot be blank') })
        count = BookingDetailScheme.count
        expect { patch :update, params: { user_request_swap: user_request_params, request_type: 'swap', id: user_request.id } }.to change { BookingDetail.count }.by(0)
        # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
        expect(user_request.reload.status).to eq('rejected')
        expect(booking_detail.reload.status).to eq('blocked')
        expect(booking_detail.reload.project_unit.status).to eq('blocked')
        expect(alternate_project_unit.reload.status).to eq('available')
        expect(BookingDetailScheme.count).to eq(count)
      end

      it 'making old project unit available failed, user_request rejected, booking detail changes to blocked' do
        booking_detail = book_project_unit(@user)
        booking_detail_scheme = create(:booking_detail_scheme, derived_from_scheme_id: @scheme.id, booking_detail: booking_detail, status: 'approved', project_unit_id: booking_detail.project_unit_id, user_id: booking_detail.user_id)
        alternate_project_unit = create(:project_unit)
        user_request = create(:pending_user_request_swap, project_unit_id: booking_detail.project_unit_id, alternate_project_unit_id: alternate_project_unit.id, user_id: booking_detail.user_id, created_by_id: @admin.id, booking_detail_id: booking_detail.id, event: 'pending')
        user_request_params = { event: 'processing', user_id: @user.id }
        ProjectUnit.any_instance.stub(:save).and_return false
        ProjectUnit.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(ProjectUnit.new).tap { |e| e.add(:status, 'cannot be blank') })
        count = BookingDetailScheme.count
        expect { patch :update, params: { user_request_swap: user_request_params, request_type: 'swap', id: user_request.id } }.to change { BookingDetail.count }.by(0)
        # expect(ProjectUnitCancelWorker.jobs.size).to eq(1)
        expect(user_request.reload.status).to eq('rejected')
        expect(booking_detail.reload.status).to eq('blocked')
        expect(booking_detail.reload.project_unit.status).to eq('blocked')
        expect(alternate_project_unit.reload.status).to eq('available')
        expect(BookingDetailScheme.count).to eq(count)
      end
    end
  end
end
