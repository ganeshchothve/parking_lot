class CustomDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include ApplicationHelper
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default from: :current_from_address, template_path: 'layouts/mailer' # to make sure that your mailer uses the devise views
end
