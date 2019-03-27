module UserRequestStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :pending, initial: true
      state :processing, :resolved, :rejected

      event :pending, after: :update_booking_detail_to_request_made do
        transitions from: :pending, to: :pending
      end

      event :processing do
        after do
          booking_detail.current_user_request = self
          update_booking_detail_to_cancelling if is_a?(UserRequest::Cancellation)
          update_booking_detail_to_swapping if is_a?(UserRequest::Swap)
        end
        transitions from: :processing, to: :processing
        transitions from: :pending, to: :processing
      end

      event :resolved, after: :update_request do
        transitions from: :resolved, to: :resolved
        transitions from: :processing, to: :resolved
      end

      event :rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected, after: :update_booking_detail_to_request_rejected
        transitions from: :processing, to: :rejected
      end
    end

    def update_request
      resolved_at = Time.now
    end

    def update_booking_detail_to_request_made
      booking_detail.cancellation_requested! if is_a?(UserRequest::Cancellation)
      booking_detail.swap_requested! if is_a?(UserRequest::Swap)
      UserRequestService.new(self)
    end

    def update_booking_detail_to_request_rejected
      # SANKET
      booking_detail.cancellation_rejected! if is_a?(UserRequest::Cancellation)
      booking_detail.swap_rejected! if is_a?(UserRequest::Swap)
      self.reason_for_failure = 'admin rejected the request' if reason_for_failure.blank?
    end

    def update_booking_detail_to_cancelling
      booking_detail.cancelling!
    end

    def update_booking_detail_to_swapping
      booking_detail.swapping!
      ProjectUnitSwapWorker.perform_in(30.seconds, id)
    end
  end
end
