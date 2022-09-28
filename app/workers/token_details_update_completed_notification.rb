class TokenDetailsUpdateCompletedNotification
  include Sidekiq::Worker
  sidekiq_options queue: 'discount'

  def perform current_user_id
    user = User.find current_user_id
    if user
      email_template = ::Template::EmailTemplate.where(name: "update_token_details_completed")
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
