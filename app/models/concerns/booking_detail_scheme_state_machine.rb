module BookingDetailSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :draft, initial: true
      state :approved, :disabled, :under_negotiation, :negotiation_failed

      event :draft do
        transitions from: :draft, to: :draft
      end

      event :under_negotiation do
        transitions from: :draft, to: :under_negotiation, if: :editable_payment_adjustments_present?
        transitions from: :under_negotiation, to: :under_negotiation
      end

      event :negotiation_failed do
        transitions from: :under_negotiation, to: :negotiation_failed, after: :update_project_unit
        transitions from: :negotiation_failed, to: :negotiation_failed
      end

      event :approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, if: unless: :editable_payment_adjustments_present?
        transitions from: :under_negotiation, to: :approved
      end

      event :disabled do
        transitions from: :disabled, to: :disabled
        transitions from: :draft, to: :disabled, if: :other_approved_scheme_present?
        transitions from: :approved, to: :disabled, if: :other_approved_scheme_present?
      end

    end

    def editable_payment_adjustments_present?
      self.editable_payment_adjustments.count > 0
    end

    def other_approved_scheme_present?
      BookingDetailScheme.where(project_unit_id: self.project_unit_id, user_id: self.user_id, status: "approved").count > 1
    end

    def update_project_unit
      self.project_unit.set(status: self.status)
    end
  end
end
