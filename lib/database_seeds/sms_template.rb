module DatabaseSeeds
  module SmsTemplate
    def self.seed client_id
      Template::SmsTemplate.create({booking_portal_client_id: client_id, subject_class: "User", name: "otp", content: "Your OTP for logging into <%= booking_portal_client.name %> is <%= otp_code %>."})  if Template::SmsTemplate.where(name: "otp").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_created", content: "We're sorry to see you go! Your request for cancellation of booking for <%= project_unit.name %> has been received. Our CRM team will get in touch with you shortly.") if Template::SmsTemplate.where(name: "cancellation_request_created").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_success", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> was successful (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "receipt_success").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_failed", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has failed (<%= receipt_id %>).") if Template::SmsTemplate.where(name: "receipt_failed").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_pending", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has been collected and will be sent to the <%= user.name %> Team for clearance.") if Template::SmsTemplate.where(name: "receipt_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_clearance_pending", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> is under 'Pending Clearance' (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "receipt_clearance_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "promote_future_payment_6", content: "Only 6 days to go! 6 days to being part of <%= booking_portal_client.name %>. Click here to pay the pending amount of Rs. <%= pending_balance %> for unit <%= name %> and secure your home at <%= project_name %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_6").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "promote_future_payment_5", content: "A home, an identity - come home to yours. Only 5 days to go before you miss your home at <%= project_name %>! Get it before you regret it. Click here to complete paying the pending amount: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_5").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "promote_future_payment_4", content: "You buy electronics online, you buy groceries online - why not a home? Complete your pending amount of Rs. <%= pending_balance %> for unit <%= name %> at <%= project_name %> on the portal, before you miss your home. You've got only 4 days to go! Click to pay: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_4").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "promote_future_payment_3", content: "A lot can happen in 3 days - today, you have a home at the prestigious <%= booking_portal_client.name %> reserved in your name. 3 days from now, you could've missed that opportunity. Click here to pay the pending amount of Rs. <%= pending_balance %> for unit <%= name %> today: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_3").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "promote_future_payment_2", content: "2 days to go! 2 days until you've missed your home at <%= project_name %> - or, you could be the proud resident of <%= booking_portal_client.name %> today. Click here to complete the transaction of Rs. <%= pending_balance %> for unit <%= name %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_2").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "promote_future_payment_1", content: "Today's your last chance to call <%= name %> at <%= project_name %> your home! Complete the payment today, or the apartment will get auto-released for other users to book it. Click here to complete your payment of Rs. <%= pending_balance %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_1").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "project_unit_released", content: "Dear <%= name %>, you missed out! We regret to inform you that the apartment you shortlisted has been released. Click here if you'd like to re-start the process: <%= dashboard_url %> Your cust ref id is <%= lead_id %>") if Template::SmsTemplate.where(name: "project_unit_released").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "project_unit_blocked", content: "Congratulations <%= user.name %>, <%= name %> has been Blocked / Tentative Booked for you for the next 7 days! To own the home, you'll need to pay the pending amount of Rs. <%= project_unit.pending_balance %> within these 7 days. To complete the payment now, click here: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "project_unit_blocked").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "ProjectUnit", name: "project_unit_booked_confirmed", content: "Welcome to the <%= booking_portal_client.name %> family! You're now the proud owner of <%= name %> at <%= project_name %> in <%= booking_portal_client.name %>. Our executives will be in touch regarding agreement formalities.") if Template::SmsTemplate.where(name: "project_unit_booked_confirmed").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "user_registered_by_channel_partner", content: "<%= manager.name %> has registered you with <%= booking_portal_client.name %>. To confirm your account with this partner, please click <%= confirmation_url %>. You can also confirm your account using your phone & OTP.") if Template::SmsTemplate.where(name: "user_registered_by_channel_partner").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "channel_partner_user_registered", content: "Dear <%= name %>, thank you for registering as a Channel Partner at <%= booking_portal_client.name %>. To confirm your account, please click <%= confirmation_url %>. You can also confirm your account using your phone & OTP.") if Template::SmsTemplate.where(name: "channel_partner_user_registered").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "user_registered", content: "Dear <%= name %>, thank you for registering at <%= booking_portal_client.name %>. To confirm your account, please click <%= confirmation_url %>. You can also confirm your account using your phone & OTP.") if Template::SmsTemplate.where(name: "user_registered").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Client", name: "daily_sms_report", content: 'Blocked: <%= ProjectUnit.where(status: "blocked").count %>. Tentative: <%= ProjectUnit.where(status: "booked_tentative").count %>. Confirmed: <%= ProjectUnit.where(status: "booked_confirmed").count %>. Blocked Today: <%= ProjectUnit.where(blocked_on: Date.today).count %>.     *subject to cancellations') if Template::SmsTemplate.where(name: "daily_sms_report").blank?

      return Template::SmsTemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
