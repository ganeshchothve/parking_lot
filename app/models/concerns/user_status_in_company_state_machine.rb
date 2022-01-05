module UserStatusInCompanyStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    field :user_status_in_company, type: String, default: :inactive

    aasm :company, column: :user_status_in_company, whiny_transitions: false do
      state :inactive, initial: true
      state :pending_approval, :active

      event :pending_approval do
        transitions from: :inactive, to: :pending_approval
      end

      event :active do
        transitions from: :inactive, to: :active
        transitions from: :pending_approval, to: :active
      end

      event :inactive do
        transitions from: :active, to: :inactive
        transitions from: :pending_approval, to: :inactive
      end
    end
  end
end