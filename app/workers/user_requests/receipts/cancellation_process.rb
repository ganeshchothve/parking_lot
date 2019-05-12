module UserRequests
	module Receipts
    class CancellationProcess
      include Sidekiq::Worker
      def perform(user_request_id)
        @user_request = UserRequest.processing.where(_id: user_request_id).first
        return nil if @user_request.blank?
        @receipt = @user_request.requestable
        if @receipt && @receipt.cancelling?
          @receipt.cancelled!
          @user_request.resolved!
        else
          reject_user_request([], [], 'Receipt is not available for cancellation.')
        end 
      end
    end
  end
end