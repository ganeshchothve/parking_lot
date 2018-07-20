class ApplicationMailer < ActionMailer::Base
  default from: -> {
    client = Client.where(id: RequestStore::Base.get("client_id")).first
    if client.present?
      client.name + " <" + client.notification_email + ">"
    else
      "Notification <no-reply@bookingportal.com>"
    end
  }
  layout 'mailer'
  helper ApplicationHelper
end
