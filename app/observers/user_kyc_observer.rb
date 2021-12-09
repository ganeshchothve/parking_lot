class UserKycObserver < Mongoid::Observer
  def before_validation user_kyc
    user_kyc.user_id = user_kyc.lead.user_id unless user_kyc.user.present?
    if user_kyc.lead.user_kyc_ids.blank?
      user_kyc.email ||= user_kyc.lead.email
      user_kyc.phone ||= user_kyc.lead.phone
    end
  end

  def after_create user_kyc
    lead = user_kyc.lead
    lead.set(kyc_done: true)
    user = lead.user
    SelldoLeadUpdater.perform_async(lead.id.to_s, {stage: 'kyc_done'})
    template = Template::EmailTemplate.where(name: "user_kyc_added", project_id: lead.project_id).first
    if user.booking_portal_client.email_enabled? && template.present?
      email = Email.create!({
        booking_portal_client_id: user.booking_portal_client_id,
        email_template_id: template.id,
        to: [user_kyc.email],
        recipients: [user_kyc],
        cc: user.booking_portal_client.notification_email.to_s.split(',').map(&:strip),
        triggered_by_id: user_kyc.id,
        triggered_by_type: user_kyc.class.to_s
      })
      email.sent!
      PaymentReminderWorker.perform_at(Time.now + 1.hour, {user_id: user.id, project_id: lead.project_id}) if lead.receipts.blank?
    end
  end
end
