require 'rails_helper'
RSpec.describe UserRequests::Receipts::CancellationProcess, type: :worker do
  describe "User Request is made" do
    before(:each) do
      @admin = create(:admin)
      @user = create(:user)
      @receipt = create(:receipt, payment_mode: 'online', user_id: @user.id, total_amount: 50_000, status: 'success')
      @user_request = create(:pending_user_request_cancellation, user_id: @receipt.user_id, created_by_id: @admin.id,requestable_id: @receipt.id, requestable_type: 'Receipt', event: 'pending')
      @user_request.set(status: 'processing', resolved_by_id: @admin.id)
    end

    context " and wrong user_request_id is sent " do
      it "then ignore request" do
        expect( UserRequests::BookingDetails::CancellationProcess.new.perform('asddff') ).to eq(nil)
      end
    end
    context "and receipt is present" do
      context "and receipt is in cancelling state" do
        it "then receipt will go to available for refund state and user_request to resolved" do
          @receipt.set(status: 'cancelling')
          UserRequests::Receipts::CancellationProcess.new.perform(@user_request.id)
          expect( @user_request.reload.status).to eq('resolved')
          expect(@receipt.reload.status).to eq ("available_for_refund")
          expect(@receipt.reload.token_number).to eq (nil)
        end
      end

      context "and receipt is not in cancelling state" do
        it "then user_request will be rejected" do
          UserRequests::Receipts::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to eq('Receipt is not available for cancellation.')
        end
      end
    end

    context "and receipt is not present" do
      it "then user_request will be rejected" do
        UserRequests::Receipts::CancellationProcess.new.perform(@user_request.id)
          expect(@user_request.reload.status).to eq('rejected')
          expect(@user_request.reason_for_failure).to eq('Receipt is not available for cancellation.')
      end
    end
  end
end