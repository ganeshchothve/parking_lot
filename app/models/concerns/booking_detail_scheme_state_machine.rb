module BookingDetailSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :draft, initial: true
      state :approved, :disabled

      event :draft do
        transitions from: :draft, to: :draft
      end

      event :under_negotiation do
        transitions from: :draft, to: :under_negotiation
        transitions from: :under_negotiation, to: :under_negotiation
      end

      event :approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, unless: :new_record?, if: :booking_detail_present?
      end

      event :disabled do
        transitions from: :disabled, to: :disabled
        transitions from: :draft, to: :disabled, unless: :new_record?
        transitions from: :approved, to: :disabled
      end

    end

    def booking_detail_present?
      self.booking_detail.present?
    end
  end
end
