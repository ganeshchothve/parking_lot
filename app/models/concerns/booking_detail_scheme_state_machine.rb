module BookingDetailSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :approved, :rejected

      event :draft do
        transitions from: :draft, to: :draft
        transitions from: :approved, to: :draft
      end

      event :approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, if: :booking_detail_present?
      end

      event :rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :draft, to: :rejected
        transitions from: :approved, to: :rejected, if: :other_approved_scheme_present?
      end
    end

    def booking_detail_present?
      booking_detail.present?
    end

    def editable_payment_adjustments_present?
      editable_payment_adjustments.count > 0
    end

    def other_approved_scheme_present?
      BookingDetailScheme.where(project_unit_id: project_unit_id, user_id: user_id, status: 'approved').count > 1
    end
  end
end
