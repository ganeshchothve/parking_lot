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

      event :processing, after: :update_booking_detail_to_cancelling do
        transitions from: :pending, to: :processing
      end

      event :resolved do
        transitions from: :resolved, to: :resolved
        transitions from: :processing, to: :resolved
      end

      event :rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected, after: :update_booking_detail_to_cancellation_rejected
        transitions from: :processing, to: :rejected
      end
    end

    def update_booking_detail_to_request_made
      booking_detail.cancellation_requested! if is_a?(UserRequest::Cancellation)
      booking_detail.swap_requested! if is_a?(UserRequest::Swap)
    end

    def update_booking_detail_to_cancellation_rejected
      # SANKET
      booking_detail.cancellation_rejected!
    end

    def update_booking_detail_to_cancelling
      booking_detail.current_user_request = self
      booking_detail.cancelling!
    end
  end
end
