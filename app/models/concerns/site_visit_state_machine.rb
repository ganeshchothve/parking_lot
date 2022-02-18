module SiteVisitStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM

    attr_accessor :event, :approval_event
    field :status, type: String, default: 'scheduled'
    field :approval_status, type: String, default: 'pending'

    # SiteVisit status state machine
    aasm :status, column: :status, whiny_transitions: false do
      state :scheduled, initial: true
      state :pending, :missed, :conducted, :paid

      event :conduct, after: %i[send_notification] do
        transitions from: :scheduled, to: :conducted, if: :can_conduct?
        transitions from: :pending, to: :conducted, if: :can_conduct?
      end

      event :paid, after: %i[send_notification] do
        transitions from: :conducted, to: :paid, if: :verification_approved?
      end
    end

    def can_schedule?
      scheduled_on >= Time.now
    end

    def can_conduct?
      scheduled_on < Time.now
    end

    def send_notification
      template_name = "site_visit_status_#{self.status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
      recipient = self.manager || self.lead.manager
      send_push_notification(template_name, recipient) if recipient.present?
    end

    # State machine for approval status maintained on a separate field
    aasm :approval_status, column: :approval_status, whiny_transitions: false, namespace: :verification do
      state :pending, initial: true
      state :approved, :rejected

      event :approve, before: :mark_conducted, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :approved, if: :can_approve?
        transitions from: :rejected, to: :approved, if: :can_approve?
      end

      event :reject, after: %i[send_approval_status_notification] do
        transitions from: :pending, to: :rejected, if: :can_reject?
      end
    end

    def can_approve?
      scheduled_on < Time.now
    end

    def can_reject?
      scheduled_on < Time.now
    end

    def mark_conducted
      self.conduct if self.may_conduct?
    end

    def send_approval_status_notification
      template_name = "site_visit_approval_status_#{self.approval_status}_notification"
      # TODO: Send Broadcast message via notification, in-app, Email, etc
      recipient = self.manager || self.lead.manager
      send_push_notification(template_name, recipient) if recipient.present?
    end

    def send_push_notification template_name, recipient
      template = Template::NotificationTemplate.where(name: template_name).first
      if template.present? && recipient.booking_portal_client.notification_enabled?
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
  end
end
