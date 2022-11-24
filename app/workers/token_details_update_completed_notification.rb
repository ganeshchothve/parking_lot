class TokenDetailsUpdateCompletedNotification
  include Sidekiq::Worker
  sidekiq_options queue: 'discount'

  def perform current_user_id
    user = User.where(id: current_user_id).first
    booking_portal_client_id =  user.try(:booking_portal_client_id)
    if user
      email_template = ::Template::EmailTemplate.where(name: "update_token_details_completed", booking_portal_client_id: booking_portal_client_id).first
      if email_template.present?
        email = Email.create!(
          booking_portal_client_id: user.booking_portal_client_id,
          email_template_id: email_template.first.id,
          cc: [],
          recipients: [user],
          cc_recipients: [],
          triggered_by_id: current_user_id,
          triggered_by_type: "User"
        )
        email.sent!
      end
    end
  end
end
