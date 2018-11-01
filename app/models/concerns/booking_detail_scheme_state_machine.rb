module BookingDetailSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :draft, initial: true
      state :approved, :disabled, :under_negotiation

      event :draft do
        transitions from: :draft, to: :draft
      end

      event :under_negotiation do
        transitions from: :draft, to: :under_negotiation, if: :booking_detail_present?
        transitions from: :under_negotiation, to: :under_negotiation
      end

      event :approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, if: :booking_detail_present?
        transitions from: :under_negotiation, to: :approved, if: :booking_detail_present?
      end

      event :disabled do
        transitions from: :disabled, to: :disabled
        transitions from: :draft, to: :disabled, if: :other_approved_scheme_present?
        transitions from: :approved, to: :disabled, if: :other_approved_scheme_present?
      end

    end

    def booking_detail_present?
      self.booking_detail.present?
    end

    def other_approved_scheme_present?
      BookingDetailScheme.where(project_unit_id: self.project_unit_id, user_id: self.user_id, status: "approved").count > 1
    end
  end
end
