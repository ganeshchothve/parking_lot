class UserKycObserver < Mongoid::Observer
  def before_validation user_kyc
    if user_kyc.user.user_kyc_ids.blank?
      user_kyc.email ||= user_kyc.user.email
      user_kyc.phone ||= user_kyc.user.phone
    end
  end

  def after_create user_kyc
    SelldoLeadUpdater.perform_async(user_kyc.user_id.to_s, 'kyc_done')
    template = Template::EmailTemplate.where(name: "user_kyc_added").first
    if user_kyc.user.booking_portal_client.email_enabled? && template.present?
      email = Email.create!({
        booking_portal_client_id: user_kyc.user.booking_portal_client_id,
        email_template_id: template.id,
        to: [user_kyc.email],
        recipients: [user_kyc],
        triggered_by_id: user_kyc.id,
        triggered_by_type: user_kyc.class.to_s
      })
      email.sent!
    end

  end
end
