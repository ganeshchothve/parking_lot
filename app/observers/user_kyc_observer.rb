class UserKycObserver < Mongoid::Observer
  def after_create user_kyc
    SelldoLeadUpdater.perform_async(user_kyc.user_id.to_s)

    Email.create!({
      booking_portal_client_id: user_kyc.user.booking_portal_client_id,
      email_template_id: EmailTemplate.find_by(name: "user_kyc_added").id,
      to: [user_kyc.email],
      recipients: [user_kyc],
      triggered_by_id: user_kyc.id,
      triggered_by_type: user_kyc.class.to_s
    })

  end
end
