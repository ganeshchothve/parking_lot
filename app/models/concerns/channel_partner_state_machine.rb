module ChannelPartnerStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    aasm column: :status, whiny_transitions: false do
      state :inactive, initial: true
      state :active, :pending, :rejected

      event :submit_for_approval, after: %i[update_selldo! after_submit_for_approval] do
        transitions from: :inactive, to: :pending, if: :can_send_for_approval?
        transitions from: :rejected, to: :pending, if: :can_send_for_approval?
      end

      event :approve, after: %i[update_selldo! send_notification update_project_ids] do
        transitions from: :pending, to: :active
        transitions from: :inactive, to: :active
      end

      event :reject, after: %i[update_selldo! send_notification] do
        transitions from: :pending, to: :rejected
      end

      # event :disable, after: %i[send_notification]  do
      #   transitions from: :active, to: :inactive
      # end
    end

    def can_send_for_approval?
      self.valid?(:submit_for_approval)
    end

    def after_submit_for_approval
      self.set( status_change_reason: nil )
      send_notification
    end

    def send_notification
      template_name = "channel_partner_status_#{self.status}"
      template = Template::EmailTemplate.where(name: template_name, booking_portal_client_id: self.booking_portal_client_id).first
      recipients = self.users.cp_owner.to_a
      recipients << self.manager if self.manager.present?
      recipients << self.manager.manager if self.manager.try(:manager).present?

      if template.present?
        email = Email.create!({
          booking_portal_client_id: self.users.first&.booking_portal_client_id,
          email_template_id: template.id,
          recipients: recipients.flatten,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s
        })
        email.sent!
      end

      sms_template = Template::EmailTemplate.where(name: template_name, booking_portal_client_id: self.booking_portal_client_id).first
      if sms_template.present?
        phones = recipients.collect(&:phone).reject(&:blank?)
        if phones.present?
          Sms.create!(
            booking_portal_client_id: self.users.first&.booking_portal_client_id,
            to: phones,
            sms_template_id: sms_template.id,
            triggered_by_id: self.id,
            triggered_by_type: self.class.to_s
          )
        end
      end
      # send notification
      recipient = self.primary_user
      send_push_notification(template_name, recipient) if recipient.present?
    end

    def send_push_notification template_name, recipient
      template = Template::NotificationTemplate.where(name: template_name, booking_portal_client_id: self.booking_portal_client_id).first
      if template.present? && template.is_active? && users.first&.booking_portal_client.notification_enabled?
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

    def update_selldo!
      self.users.each(&:set_portal_stage_and_push_in_crm)
    end

    def status_message
      case status.to_s
      when 'pending'
        I18n.t("mobile.channel_partner.status_message.#{status}")
      when 'rejected'
        I18n.t("mobile.channel_partner.status_message.#{status}", reason: status_change_reason&.html_safe)
      else
        nil
      end
    end

    def update_project_ids
      if self.booking_portal_client.is_marketplace?
        project_ids = self.booking_portal_client.projects.where(is_active: true).distinct(:id)
        self.update(project_ids: project_ids)
      end
    end
  end
end
