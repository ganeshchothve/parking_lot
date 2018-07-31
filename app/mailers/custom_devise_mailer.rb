class CustomDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include ApplicationHelper
  extend ApplicationHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  if current_client.present?
    default from: current_client.name + " <" + current_client.notification_email + ">"
  else
    default from: "Sell.Do <support@sell.do>"
  end
  layout 'mailer'
end
