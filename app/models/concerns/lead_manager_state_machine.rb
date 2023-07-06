module LeadManagerStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM

    field :status, type: String

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :active, :tagged, :expired

      event :activate, before: :set_expiry, after: :tag_manager_on_lead do
        transitions from: :draft, to: :active
      end

      event :tag, after: :tag_manager_on_lead do
        transitions from: :active, to: :tagged, success: :remove_expiry
        transitions from: :draft, to: :tagged
      end

      event :expire do
        transitions from: :active, to: :expired
      end
    end

    def tag_manager_on_lead
      attrs = { manager_id: manager_id }
      self.lead.update(attrs)
    end

    def set_expiry
      self.expiry_date = Date.current + (project.lead_blocking_days || client.lead_blocking_days || 30).days
    end

    def remove_expiry
      self.set(expiry_date: nil)
    end

  end
end

