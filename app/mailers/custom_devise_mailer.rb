class CustomDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include ApplicationHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'layouts/mailer', from: default from: -> {
    current_client.name + " <" + current_client.notification_email + ">"
  }
end
