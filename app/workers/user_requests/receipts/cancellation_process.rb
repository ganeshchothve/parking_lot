module UserRequests
  module Receipts
    class CancellationProcess
      include Sidekiq::Worker
      attr_reader :user_request, :receipt
      def perform(user_request_id)
        @user_request = UserRequest.processing.where(_id: user_request_id).first
        return nil if @user_request.blank?
        @receipt = @user_request.requestable
        if @receipt && @receipt.cancelling?
          @receipt.cancelled!
          @user_request.resolved!
        else
          reject_user_request('Receipt is not available for cancellation.')
        end 
      end

      def reject_user_request( error_messages)
      user_request.reason_for_failure = error_messages
      unless user_request.rejected!
        # As request in invalid so its force fully rejected.
        user_request.reason_for_failure += ( ' ' + user_request.errors.full_messages.join(' ') )
        user_request.status = 'rejected'
        user_request.save(validate: false)
      end
      receipt.try(:cancellation_rejected!)
    end
    end
  end
end