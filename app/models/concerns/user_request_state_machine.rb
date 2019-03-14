module UserRequestStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :pending, initial: true
      state :processing, :resolved, :rejected

      event :pending do
        transitions from: :pending, to: :pending, after: :update_booking_detail_to_cancellation_requested
      end

      event :processing do
        transitions from: :processing, to: :processing
        transitions from: :pending, to: :processing, success: :update_booking_detail_to_cancelling
      end

      event :resolved do
        transitions from: :resolved, to: :resolved
        transitions from: :processing, to: :resolved, after: :update_booking_detail_to_cancelled
      end

      event :rejected, after: :update_booking_detail_to_cancellation_rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected
        transitions from: :processing, to: :rejected
      end
    end

    def update_booking_detail_to_cancellation_rejected
      booking_detail.cancellation_rejected!
      ProjectUnitCancelService.new(self).reject if pending?
    end

    def update_booking_detail_to_cancelled
      booking_detail.cancelled! # if self.type == 'cancellation'
    end

    def update_booking_detail_to_cancellation_requested
      booking_detail.cancellation_requested! # if self.type == 'cancellation'
    end

    def update_booking_detail_to_cancelling
      booking_detail.cancelling! unless booking_detail.cancelled?
      ProjectUnitCancelService.new(self).resolve
    end
  end
end
