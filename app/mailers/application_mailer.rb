class ApplicationMailer < ActionMailer::Base
  helper ApplicationHelper
  default from: :current_from_address
  layout 'mailer'
end
