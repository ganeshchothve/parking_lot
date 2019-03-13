module UserRequestStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :pending, initial: true
      state :processing, :resolved, :rejected

      event :pending do
        transitions from: :pending, to: :pending, after: :update_booking_detail_to_requested
      end

      event :processing do
        transitions from: :processing, to: :processing
        transitions from: :pending, to: :processing, after: :update_booking_detail_to_cancelling
      end

      event :resolved do
        transitions from: :resolved, to: :resolved
        transitions from: :processing, to: :resolved
      end

      event :rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected
        transitions from: :processing, to: :rejected, before: :update_booking_detail_to_rejected
      end
    end

    def update_booking_detail_to_requested
      booking_detail.cancellation_requested! # if self.type == 'cancellation'
    end

    def update_booking_detail_to_cancelling
      booking_detail.cancelling! # if self.type == 'cancellation'
    end

    def update_booking_detail_to_rejected
      booking_detail.cancellation_rejected!
    end
  end
end
