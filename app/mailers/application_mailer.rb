class ApplicationMailer < ActionMailer::Base
  helper ApplicationHelper
  include ApplicationHelper
  extend ApplicationHelper

  if current_client
    default from: "#{current_client.name} <#{current_client.sender_email}>", cc: "#{current_client.notification_email}"
  else
    default from: "Sell.Do <support@sell.do>"
  end
  layout 'mailer'
end
