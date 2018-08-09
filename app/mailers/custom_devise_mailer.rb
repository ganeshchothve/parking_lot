class CustomDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include ApplicationHelper
  extend ApplicationHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  if current_client.present?
    default from: current_client.name + " <" + current_client.sender_email + ">"
  else
    default from: "Sell.Do <support@sell.do>"
  end
  layout 'mailer'
end

module Devise::Mailers::Helpers
  protected
  def devise_mail record, action, opts = {}, &block
    initialize_from_record(record)
    devise_sms(record, action, opts)
    make_bootstrap_mail headers_for(action, opts), &block
  end

  def devise_sms record, action, opts = {}
    begin
      if action.to_s == "confirmation_instructions"
        if record.buyer? && record.channel_partner_id.present?
          template_id = SmsTemplate.find_by(name: "user_registered_by_channel_partner").id
        elsif record.role == "channel_partner"
          template_id = SmsTemplate.find_by(name: "channel_partner_user_registered").id
        else
          template_id = SmsTemplate.find_by(name: "user_registered").id
        end
      elsif action.to_s == "resend_confirmation_instructions"
        template_id = SmsTemplate.find_by(name: "user_registered").id
      else
        # GENERICTODO : Will work once we get urls to start working in templates
        # template_id = SmsTemplate.find_by(name: "devise_#{action}").id
      end
      if template_id
        Sms.create!(
          booking_portal_client_id: record.booking_portal_client_id,
          recipient_id: record.id,
          sms_template_id: template_id,
          triggered_by_id: record.id,
          triggered_by_type: record.class.to_s
        )
      end
    rescue => e
    end
  end
end
