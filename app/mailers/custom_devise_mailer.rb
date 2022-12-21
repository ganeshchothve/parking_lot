class CustomDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include ApplicationHelper
  extend ApplicationHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  layout 'devise_mailer'
end

module Devise::Mailers::Helpers
  protected
  def devise_mail record, action, opts = {}, &block
    initialize_from_record(record)
    devise_sms(record, action, opts)
    make_bootstrap_mail headers_for(action, opts.merge({from: record.booking_portal_client.sender_email})), &block
  end

  def devise_sms record, action, opts = {}
    begin
      if action.to_s == "confirmation_instructions"
        if record.buyer? && record.manager_role?("channel_partner")
          template = Template::SmsTemplate.where(name: "user_registered_by_channel_partner", booking_portal_client_id: record.booking_portal_client_id).first
        else
          template = Template::SmsTemplate.where(name: "#{record.role}_user_registered", booking_portal_client_id: record.booking_portal_client_id).first
          template = Template::SmsTemplate.where(name: "user_registered", booking_portal_client_id: record.booking_portal_client_id).first if template.blank?
        end
      elsif action.to_s == "resend_confirmation_instructions"
        template = Template::SmsTemplate.where(name: "user_registered", booking_portal_client_id: record.booking_portal_client_id).first
      else
        # GENERICTODO : Will work once we get urls to start working in templates
        # template = Template::SmsTemplate.find_by(name: "devise_#{action}").id
      end
      if template && template.is_active? && record.booking_portal_client.sms_enabled?
        Sms.create!(
          booking_portal_client_id: record.booking_portal_client_id,
          recipient_id: record.id,
          sms_template_id: template.id,
          triggered_by_id: record.id,
          triggered_by_type: record.class.to_s
        )
      end
    rescue => e
    end
  end
end
