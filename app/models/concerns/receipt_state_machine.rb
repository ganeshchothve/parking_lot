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

      event :success do
        transitions from: :success, to: :success
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
        transitions from: :success, to: :cancelled, if: :swap_request_initiated?
        transitions from: :clearance_pending, to: :cancelled, if: :swap_request_initiated?
      end

    end

    def can_available_for_refund?
      self.booking_detail.blank? || self.booking_detail.status == "cancelled"
    end

    def can_move_to_clearance?
      self.persisted? || self.project_unit_id.present?
    end

    def swap_request_initiated?
      self.swap_request_initiated == true
    end
  end
end
