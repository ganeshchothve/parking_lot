module SchemeStateMachine
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

      event :approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, unless: :new_record?
      end

      event :disabled do
        transitions from: :disabled, to: :disabled
        transitions from: :draft, to: :disabled, unless: :new_record?
        transitions from: :approved, to: :disabled
      end
    end
  end
end
