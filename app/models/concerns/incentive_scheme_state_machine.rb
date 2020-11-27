module IncentiveSchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :approved, :disabled

      event :draft, after: :after_draft_event do
        transitions from: :draft, to: :draft
      end

      event :approved, after: :after_approved_event do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved
      end

      event :disabled, after: :after_disabled_event do
        transitions from: :disabled, to: :disabled
        transitions from: :draft, to: :disabled
        transitions from: :approved, to: :disabled, if: :can_move_to_disabled?
      end
    end

    def after_draft_event
    end
    def after_approved_event
    end
    def after_disabled_event
    end

    def can_move_to_disabled?
      if aasm.from_state.to_s == 'approved'
        Date.current < starts_on
      end
    end
  end
end
