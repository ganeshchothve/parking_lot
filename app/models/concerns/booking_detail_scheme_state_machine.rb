module BookingDetailSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :draft, initial: true
      state :approved, :rejected

      event :draft do
        transitions from: :draft, to: :draft
      end

      event :approved, after: :after_approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, if: :booking_detail_present?
      end

      event :disabled do
        transitions from: :rejected, to: :rejected
        transitions from: :draft, to: :rejected, if: :other_approved_scheme_present?
        transitions from: :approved, to: :rejected, if: :other_approved_scheme_present?
      end

    end

    def booking_detail_present?
      self.booking_detail.present?
    end

    def editable_payment_adjustments_present?
      self.editable_payment_adjustments.count > 0
    end

    def other_approved_scheme_present?
      BookingDetailScheme.where(project_unit_id: self.project_unit_id, user_id: self.user_id, status: "approved").count > 1
    end

    def after_approved
      self.booking_detail.after_under_negotiation
    end
  end
end
