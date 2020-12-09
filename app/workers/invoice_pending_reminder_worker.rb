class InvoicePendingReminderWorker
  include Sidekiq::Worker
  include ApplicationHelper

  def perform
    if current_client.email_enabled?
      if email_template = Template::EmailTemplate.where(name: 'invoice_pending_approvals_list').first
          recipients = User.where(role: 'cp_admin')
          recipients.each do |recipient|
            email = Email.create!(
              booking_portal_client_id: current_client.id,
              email_template_id: email_template.id,
              recipients: recipients,
              cc: [],
              cc_recipients: [],
              triggered_by_id: recipient.id,
              triggered_by_type: recipient.class.to_s
            )
            email.sent!
          end
        end
    end
  end
end
