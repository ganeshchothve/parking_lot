module UserRequestStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    aasm column: :status do
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

      event :rejected do
        transitions from: :rejected, to: :rejected
        transitions from: :pending, to: :rejected, after: :update_requestable_to_request_rejected
        transitions from: :processing, to: :rejected, after: :send_notifications
      end
    end

    def update_request
      resolved_at = Time.now
      send_notifications
    end

    def send_email
      Email.create!(
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id: Template::EmailTemplate.find_by(name: "#{self.class.model_name.element}_request_#{status}").id,
        recipients: [user],
        cc_recipients: (user.manager_id.present? ? [user.manager] : []),
        triggered_by_id: id,
        triggered_by_type: self.class.to_s
      )
    end

    def send_sms
      template = Template::SmsTemplate.where(name: "#{self.class.model_name.element}_request_resolved").first
      if template.present? && user.booking_portal_client.sms_enabled?
        Sms.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          recipient_id: user_id,
          sms_template_id: template.id,
          triggered_by_id: id,
          triggered_by_type: self.class.to_s
        )
      end
    end

    def update_requestable_to_request_made
      requestable.cancellation_requested! if is_a?(UserRequest::Cancellation)
      requestable.swap_requested! if is_a?(UserRequest::Swap)
      # send_notifications
    end

    def send_notifications
      send_email if user.booking_portal_client.email_enabled? && !processing?
      send_sms if user.booking_portal_client.sms_enabled? && !processing?
    end

    def update_requestable_to_request_rejected
      if self.requestable_type == 'BookingDetail'
        requestable.cancellation_rejected! if is_a?(UserRequest::Cancellation)
        requestable.swap_rejected! if is_a?(UserRequest::Swap)
        self.reason_for_failure = 'admin rejected the request' if reason_for_failure.blank?
        send_notifications
      end
      if self.requestable_type == 'Receipt'
        requestable.success!
      end
    end

    def update_requestable_to_cancelling
      if requestable_type == 'BookingDetail'
        if requestable.cancelling!
          UserRequests::CancellationProcess.perform_async(id)
        end
      elsif requestable_type == 'Receipt'
        requestable.available_for_refund!
      end
    end

    def update_requestable_to_swapping
      if requestable_type == 'BookingDetail'
        if requestable.swapping!
          UserRequests::SwapProcess.perform_async(id)
        end
      end
    end
  end
end
