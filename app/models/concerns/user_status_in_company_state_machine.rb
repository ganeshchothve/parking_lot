module UserStatusInCompanyStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :user_status_in_company_event

    field :user_status_in_company, type: String, default: :inactive

    aasm :company, column: :user_status_in_company, whiny_transitions: false do
      state :inactive, initial: true
      state :pending_approval, :active

      event :pending_approval do
        transitions from: :inactive, to: :pending_approval
      end

      event :active, after: :set_channel_partner do
        transitions from: :inactive, to: :active
        transitions from: :pending_approval, to: :active
      end

      event :inactive do
        transitions from: :active, to: :inactive
        transitions from: :pending_approval, to: :inactive
      end
    end

    # Add user account in existing company as channel partner
    def set_channel_partner(new_company=false)
      unless new_company
        attrs = {channel_partner: temp_channel_partner}
        attrs[:role] = 'channel_partner'
        self.update(attrs)
      end
    end
  end
end
