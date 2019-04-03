module ReceiptStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :pending, initial: true
      state :success, :clearance_pending, :failed, :available_for_refund, :refunded, :cancelled

      event :pending, after: %i[moved_to_clearance_pending] do
        transitions from: :pending, to: :pending
      end

      event :clearance_pending, after: %i[moved_to_success_if_online change_booking_detail_status] do
        transitions from: :pending, to: :clearance_pending, if: :can_move_to_clearance?
        transitions from: :clearance_pending, to: :clearance_pending
      end

      event :success, after: %i[change_booking_detail_status] do
        transitions from: :success, to: :success
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
        transitions from: :pending, to: :cancelled, if: :user_request_initiated?
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

    def moved_to_success_if_online
      success! if payment_mode == 'online'
    end

    def user_request_initiated?
      booking_detail.swapping? || booking_detail.cancelling?
    end

    def change_booking_detail_status
      if booking_detail
        booking_detail.send("after_#{booking_detail.status}_event")
      end
    end

    #
    # When Receipt is created by admin except channel partner then it's direcly moved in clearance pening.
    #
    def moved_to_clearance_pending
      unless (%w( channel_partner ) + User::BUYER_ROLES).include?(self.creator.role)
        self.clearance_pending!
      end
    end
  end
end
