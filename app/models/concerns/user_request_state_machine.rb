module UserRequestStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
      state :pending, initial: true
      state :processing, :resolved, :rejected

      event :pending do
        transitions from: :pending, to: :pending
      end

      event :processing do
        transitions from: :processing, to: :processing
        transitions from: :pending, to: :processing
      end

      event :resolved do
        transitions from: :resolved, to: :resolved
        transitions from: :processing, to: :resolved
      end

      event :rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected
        transitions from: :processing, to: :rejected
      end
    end
  end
end
