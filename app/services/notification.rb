module Notification
  module Sms
    def self.execute params={}
      params = params.with_indifferent_access

      keys = ["booking_portal_client_id", "template_name", "recipient_id", "triggered_by_id", "triggered_by_type"].select do |key|
        params[key].blank?
      end

      fail "#{keys} required to send notification" if keys.present?

      template_name = params.delete "template_name"
      ::Sms.create!(params.merge(sms_template_id: Template::SmsTemplate.find_by(name: template_name).id))
    end
  end

  module Email
    def self.execute params={}
      params = params.with_indifferent_access

      keys = ["booking_portal_client_id", "template_name", "recipient_ids", "triggered_by_id", "triggered_by_type"].select do |key|
        params[key].blank?
      end

      fail "#{keys} required to send notification" if keys.present?

      template_name = params.delete "template_name"

      ::Email.create!(params.merge(email_template_id: Template::EmailTemplate.find_by(name: template_name).id))
    end
  end
end
