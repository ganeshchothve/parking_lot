module UserRequestStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status, whiny_transitions: false do
      state :pending, initial: true
      state :processing, :resolved, :rejected

      event :pending, after: :update_requestable_to_request_made do
        transitions from: :pending, to: :pending
      end

      event :processing do
        after do
          update_requestable_to_cancelling if is_a?(UserRequest::Cancellation)
          update_requestable_to_swapping if is_a?(UserRequest::Swap)
        end
        transitions from: :processing, to: :processing
        transitions from: :pending, to: :processing
      end

      event :resolved, after: :update_request do
        transitions from: :resolved, to: :resolved
        transitions from: :processing, to: :resolved
      end

      event :rejected, after: :update_requestable_to_request_rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected, after: :update_requestable_to_request_rejected
        transitions from: :processing, to: :rejected
      end
    end

    def update_request
      self.set(resolved_at: Time.now)
      send_notifications
    end

    def send_email
      email = Email.new(
        project_id: self.project_id,
        booking_portal_client_id: lead.user.booking_portal_client_id,
        email_template_id: Template::EmailTemplate.find_by(name: "#{self.class.model_name.element}_request_#{status}", project_id: self.project_id).id,
        recipients: [lead.user],
        cc_recipients: (lead.manager_id.present? ? [lead.manager] : []),
        cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        triggered_by_id: id,
        triggered_by_type: self.class.to_s
      )
      email.save # Had to save explicitly due to a weird bug in swap which needs debugging.
    end

    def send_sms
      template = Template::SmsTemplate.where(booking_portal_client_id: self.booking_portal_client_id, name: "#{self.class.model_name.element}_request_#{status}", project_id: self.project_id).first
      if template.present? && lead.user.booking_portal_client.sms_enabled?
        Sms.create!(
          project_id: self.project_id,
          booking_portal_client_id: lead.user.booking_portal_client_id,
          recipient_id: lead.user_id,
          sms_template_id: template.id,
          triggered_by_id: id,
          triggered_by_type: self.class.to_s
        )
      end
    end

    def send_push_notification
      template = Template::NotificationTemplate.where(booking_portal_client_id: self.booking_portal_client_id, name: "#{self.class.model_name.element}_request_#{status}").first
      if template.present? && template.is_active? && user.booking_portal_client.notification_enabled?
        push_notification = PushNotification.new(
          notification_template_id: template.id,
          triggered_by_id: self.id,
          triggered_by_type: self.class.to_s,
          recipient_id: self.user.id,
          booking_portal_client_id: self.user.booking_portal_client.id
        )
        push_notification.save
      end
    end

    def update_requestable_to_request_made
      requestable.cancellation_requested! if is_a?(UserRequest::Cancellation)
      requestable.swap_requested! if is_a?(UserRequest::Swap)
      send_notifications
    end

    def send_notifications
      send_email if lead.present? && lead.user.booking_portal_client.email_enabled? && !processing?
      send_sms if lead.present? && lead.user.booking_portal_client.sms_enabled? && !processing?
      send_push_notification if lead.present? && lead.user.booking_portal_client.notification_enabled? && !processing?
    end

    def update_requestable_to_request_rejected
      requestable.cancellation_rejected! if is_a?(UserRequest::Cancellation)
      requestable.swap_rejected! if is_a?(UserRequest::Swap)
      self.reason_for_failure = 'admin rejected the request' if reason_for_failure.blank?
      send_notifications
    end

    def update_requestable_to_cancelling
      if requestable
        requestable.cancelling!
        if Rails.env.development?
          UserRequests::BookingDetails::CancellationProcess.new.perform(id) if requestable.kind_of?(BookingDetail)
          UserRequests::Receipts::CancellationProcess.new.perform(id) if requestable.kind_of?(Receipt)
        else
          UserRequests::BookingDetails::CancellationProcess.perform_async(id) if requestable.kind_of?(BookingDetail)
          UserRequests::Receipts::CancellationProcess.perform_async(id) if requestable.kind_of?(Receipt)
        end
      end
    end

    def update_requestable_to_swapping
      if requestable_type == 'BookingDetail'
        if requestable.swapping!
          if Rails.env.development?
            UserRequests::BookingDetails::SwapProcess.new.perform(id)
          else
            UserRequests::BookingDetails::SwapProcess.perform_async(id)
          end
        end
      end
    end
  end
end
