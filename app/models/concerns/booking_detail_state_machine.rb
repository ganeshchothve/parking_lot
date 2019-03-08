module BookingDetailStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :filter, initial: true
      state :tower, :project_unit, :user_kyc
      state :hold, :blocked, :booked_tentative, :booked_confirmed, :under_negotiation, :negotiation_failed, :negotiation_approved
      state :swap_requested, :swapping, :swapped, :swap_rejected
      state :cancellation_requested, :cancelling, :cancelled, :cancellation_rejected, :cancellation_failed

      event :filter do
        transitions from: :filter, to: :filter
      end

      event :tower do
        transitions from: :tower, to: :tower
        transitions from: :filter, to: :tower
      end

      event :project_unit do
        transitions from: :project_unit, to: :project_unit
        transitions from: :tower, to: :project_unit
      end

      event :user_kyc do
        transitions from: :user_kyc, to: :user_kyc
        transitions from: :project_unit, to: :user_kyc
      end

      event :hold do
        transitions from: :hold, to: :hold
        transitions from: :user_kyc, to: :hold
      end

      event :blocked do
        transitions from: :blocked, to: :blocked
        transitions from: :hold, to: :blocked
        transitions from: :negotiation_approved, to: :blocked
        transitions from: :swap_rejected, to: :blocked
        transitions from: :cancellation_rejected, to: :blocked
        transitions from: :cancellation_failed, to: :blocked
      end

      event :booked_tentative do
        transitions from: :booked_tentative, to: :booked_tentative
        transitions from: :blocked, to: :booked_tentative
      end

      event :booked_confirmed do
        transitions from: :booked_confirmed, to: :booked_confirmed
        transitions from: :booked_tentative, to: :booked_confirmed
      end

      event :under_negotiation do
        transitions from: :under_negotiation, to: :under_negotiation
        transitions from: :hold, to: :under_negotiation
      end

      event :negotiation_failed do
        transitions from: :negotiation_failed, to: :negotiation_failed
        transitions from: :under_negotiation, to: :negotiation_failed
      end

      event :negotiation_approved do
        transitions from: :negotiation_approved, to: :negotiation_approved
        transitions from: :under_negotiation, to: :negotiation_approved
      end

      event :swap_requested do
        transitions from: :swap_requested, to: :swap_requested
        transitions from: :blocked, to: :swap_requested
        transitions from: :booked_tentative, to: :swap_requested
        transitions from: :booked_confirmed, to: :swap_requested
      end

      event :swapping do
        transitions from: :swapping, to: :swapping
        transitions from: :swap_requested, to: :swapping
      end

      event :swapped do
        transitions from: :swapped, to: :swapped
        transitions from: :swapping, to: :swapped
      end

      event :swap_rejected do
        transitions from: :swap_rejected, to: :swap_rejected
        transitions from: :swap_requested, to: :swap_rejected
      end

      event :cancellation_requested do
        transitions from: :cancellation_requested, to: :cancellation_requested
        transitions from: :blocked, to: :cancellation_requested
        transitions from: :booked_tentative, to: :cancellation_requested
        transitions from: :booked_confirmed, to: :cancellation_requested
      end

      event :cancelling do
        transitions from: :cancelling, to: :cancelling
        transitions from: :cancellation_requested, to: :cancelling
      end

      event :cancelled do
        transitions from: :cancelled, to: :cancelled
        transitions from: :cancelling, to: :cancelled
      end

      event :cancellation_failed do
        transitions from: :cancellation_failed, to: :cancellation_failed
        transitions from: :cancelling, to: :cancellation_failed
      end

      event :cancellation_rejected do
        transitions from: :cancellation_rejected, to: :cancellation_rejected
        transitions from: :cancellation_requested, to: :cancellation_rejected
      end
    end
  end
end
