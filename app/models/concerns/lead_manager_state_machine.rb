module LeadManagerStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM

    field :status, type: String

    aasm column: :status, whiny_transitions: false do
      state :draft, initial: true
      state :active, :tagged, :expired, :cancelled
      # Inactive is a placeholder state to create a lead manager in, when no tagging is to be done.
      # Use this state in exception cases such as sales scheduling revisits after a lead manager(of cp) becoming active
      state :inactive

      event :activate, before: :set_expiry, after: :tag_manager_on_lead do
        transitions from: :draft, to: :active
      end

      event :tag, after: :tag_manager_on_lead do
        transitions from: :active, to: :tagged, success: :remove_expiry
        transitions from: :draft, to: :tagged
      end

      event :expire, after: :remove_manager_on_lead do
        transitions from: :active, to: :expired
      end

      event :cancel do
        transitions from: :draft, to: :cancelled
        transitions from: :tagged, to: :cancelled, success: :remove_manager_on_lead
      end
    end

    def tag_manager_on_lead
      attrs = { manager_id: manager_id }
      self.lead.update(attrs)
    end

    def remove_manager_on_lead
      self.lead.update(manager_id: nil)
    end

    def set_expiry
      self.expiry_date = Date.current + (project.lead_blocking_days || client.lead_blocking_days || 30).days
    end

    def remove_expiry
      self.set(expiry_date: nil)
    end

  end
end

