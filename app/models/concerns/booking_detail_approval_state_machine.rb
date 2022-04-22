module BookingDetailApprovalStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM

    attr_accessor :approval_event
    field :approval_status, type: String

    aasm :approval_status, column: :approval_status, whiny_transitions: false, namespace: :verification do
      state :pending, initial: true
      state :approved, :rejected

      event :approve, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :approved
      end

      event :reject, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :rejected
      end

      event :pending do
        transitions from: :rejected, to: :pending
      end
    end

    def send_approval_status_notification
      template_name = "booking_detail_approval_status_#{self.approval_status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
      recipient = self.manager || self.lead.manager
      send_push_notification(template_name, recipient) if recipient.present?
    end

    def send_push_notification template_name, recipient
      template = Template::NotificationTemplate.where(project_id: self.lead.project_id,name: template_name).first
      if template.present? && template.is_active? && recipient.booking_portal_client.notification_enabled?
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

    def move_to_next_approval_state!(status)
      if self.respond_to?("may_#{status}?") && self.send("may_#{status}?")
        self.aasm(:approval_status).fire!(status.to_sym)
      else
        self.errors.add(:base, 'Invalid transition')
      end
      self.errors.empty?
    end

  end
end
