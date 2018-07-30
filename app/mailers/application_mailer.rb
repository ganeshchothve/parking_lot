class ApplicationMailer < ActionMailer::Base
  helper ApplicationHelper
  include ApplicationHelper
  extend ApplicationHelper

  default from: current_client.name + " <" + current_client.notification_email + ">"
  layout 'mailer'
end
