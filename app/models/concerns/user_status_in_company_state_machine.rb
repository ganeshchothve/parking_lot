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

      event :active, after: [:set_channel_partner, :clear_register_token, :after_active_event, :push_to_kylas] do
        transitions from: :inactive, to: :active
        transitions from: :pending_approval, to: :active
      end

      event :inactive, after: [:unset_channel_partner, :clear_register_token, :after_inactive_event] do
        transitions from: :active, to: :inactive
        transitions from: :pending_approval, to: :inactive
      end
    end

    # Add user account in existing company as channel partner
    def set_channel_partner(new_company=false)
      unless new_company
        attrs = {channel_partner: temp_channel_partner, manager_id: temp_channel_partner.manager_id, category: temp_channel_partner.internal_category, project_ids: temp_channel_partner.project_ids}
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

    def after_active_event
      send_notification
    end

    def after_inactive_event
      if aasm(:company).from_state.in?(%i(pending_approval))
        send_notification
      end
    end

    def send_notification
      template_name = "user_status_#{self.user_status_in_company}_in_company"
      recipient = self
      send_push_notification(template_name, recipient) if recipient.present?
    end

    def send_push_notification template_name, recipient
      template = Template::NotificationTemplate.where(booking_portal_client_id: self.booking_portal_client_id, name: template_name).first
      if template.present? && template.is_active? && self.booking_portal_client.notification_enabled?
        push_notification = PushNotification.new(
          notification_template_id: template.id,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s,
          recipient_id: recipient.id,
          booking_portal_client_id: recipient.booking_portal_client.id
        )
        push_notification.save
      end
    end

    # Push Channel Partner to Kylas as a Custom Field
    def push_to_kylas
      booking_portal_client = self.booking_portal_client
      user = booking_portal_client.users.admin.ne(kylas_access_token: nil).first
      if user.present? && booking_portal_client.is_marketplace?
        deal_custom_field_id = booking_portal_client.kylas_custom_fields.dig(:deal, :id)
        lead_custom_field_id = booking_portal_client.kylas_custom_fields.dig(:lead, :id)
        meeting_custom_field_id = booking_portal_client.kylas_custom_fields.dig(:meeting, :id)

        if deal_custom_field_id.present?
          Kylas::UpdateDealCustomField.new(user, self, deal_custom_field_id).call
        end

        if lead_custom_field_id.present?
          Kylas::UpdateLeadCustomField.new(user, self, lead_custom_field_id).call
        end

        if meeting_custom_field_id.present?
          Kylas::UpdateMeetingCustomField.new(user, self, meeting_custom_field_id).call
        end
      end
    end

  end
end
