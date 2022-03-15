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
        transitions from: :inactive, to: :pending_approval, after: :remove_rejection_reason
      end

      event :active, after: [:set_channel_partner, :clear_register_token] do
        transitions from: :inactive, to: :active
        transitions from: :pending_approval, to: :active
      end

      event :inactive, after: [:unset_channel_partner, :clear_register_token] do
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

    def clear_register_token
      if ( aasm(:company).from_state.in?(%i(pending_approval)) && aasm(:company).to_state.in?(%i(active inactive)) ) || ( aasm(:company).from_state.in?(%i(active)) && aasm(:company).to_state.in?(%i(inactive)) )
        self.set(register_in_cp_company_token: nil)
      end
    end

    def unset_channel_partner
      attrs = {}
      attrs = {channel_partner_id: nil, role: 'channel_partner'} if self.channel_partner_id.present?
      self.set(attrs) if attrs.present?
    end

    def remove_rejection_reason
      self.set(rejection_reason: nil) if self.rejection_reason.present?
    end
  end
end
