module ReceiptStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status do
      state :pending, initial: true
      state :success, :clearance_pending, :failed, :available_for_refund, :refunded, :cancelled

      event :pending do
        transitions from: :pending, to: :pending
      end

      event :clearance_pending do
        transitions from: :pending, to: :clearance_pending, if: :can_move_to_clearance?
        transitions from: :clearance_pending, to: :clearance_pending
      end

      event :success, after: :after_success do
        transitions from: :success, to: :success
        transitions from: :pending, to: :success
        # receipt moves from pending to success when online payment is made.
        transitions from: :clearance_pending, to: :success, unless: :new_record?
        transitions from: :available_for_refund, to: :success
      end

      event :available_for_refund do
        transitions from: :available_for_refund, to: :available_for_refund
        transitions from: :success, to: :available_for_refund, if: :can_available_for_refund?
      end

      event :refunded do
        transitions from: :refunded, to: :refunded
      end

      event :refund do
        transitions from: :available_for_refund, to: :refunded
      end

      event :failed do
        transitions from: :pending, to: :failed, unless: :new_record?
        transitions from: :clearance_pending, to: :failed
        transitions from: :failed, to: :failed
      end

      event :cancel do
        transitions from: :pending, to: :cancelled, if: :swap_request_initiated?
        transitions from: :success, to: :cancelled, if: :swap_request_initiated?
        transitions from: :clearance_pending, to: :cancelled, if: :user_request_initiated?
      end
    end

    def swap_request_initiated?
      booking_detail.swapping?
    end

    def can_available_for_refund?
      booking_detail.blank? || booking_detail.cancelling?
    end

    def can_move_to_clearance?
      persisted? || project_unit_id.present?
    end

    def user_request_initiated?
      booking_detail.swapping? || booking_detail.cancelling?
    end

    def after_success
      if project_unit.present?
        _project_unit = project_unit
        _project_unit.status = 'blocked'
        _project_unit.save
      end
      _booking_detail = booking_detail
      if _booking_detail.present?
        if _booking_detail.aasm.current_state == :scheme_approved
          _booking_detail.blocked! if _booking_detail.can_blocked?
        elsif _booking_detail.aasm.current_state == :blocked
          _booking_detail.booked_tentative! if _booking_detail.can_booked_tentative?
        elsif _booking_detail.aasm.current_state == :booked_tentative
          _booking_detail.booked_confirmed! if _booking_detail.can_booked_confirmed?
        end
      end
    end
  end
end
