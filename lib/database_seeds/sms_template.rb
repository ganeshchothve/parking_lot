# DatabaseSeeds::SmsTemplate.seed CLient.last.id
module DatabaseSeeds
  module SmsTemplate
    def self.seed client_id
      Template::SmsTemplate.create({booking_portal_client_id: client_id, subject_class: "User", name: "otp", content: "Your <%= I18n.t('global.otp') %> for logging into <%= booking_portal_client.name %> is <%= otp_code %>."})  if Template::SmsTemplate.where(name: "otp").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_pending", content: "
        <% if requestable.kind_of?(BookingDetail) %>
          A cancellation has been requested on your booking of <%= requestable.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing your request and will get in touch with you shortly.
        <% elsif requestable.kind_of?(Receipt) %>
          A cancellation has been requested on your payment of <%= requestable.name %> . Our CRM team is reviewing your request and will get in touch with you shortly.
        <% end %>"
        ) if Template::SmsTemplate.where(name: "cancellation_request_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_resolved", content: "
        <% if requestable.kind_of?(BookingDetail) %>
          We're sorry to see you go. Cancellation request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed and your amount will be refunded to you in a few days. To book another unit visit <%= user.dashboard_url %>
        <% elsif requestable.kind_of?(Receipt) %>
          We're sorry to see you go. Cancellation request on your payment <%= requestable.name %> has been processed and your amount will be refunded to you in a few days.
        <% end %>
          ") if Template::SmsTemplate.where(name: "cancellation_request_resolved").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_rejected", content: "
        <% if requestable.kind_of?(BookingDetail) %>
        Cancellation request on your booking of <%= requestable.name %> at <%= project_unit.project_name %> has been rejected.
        <% elsif requestable.kind_of?(Receipt) %>
          Cancellation request on your payment <%= requestable.name %> has been rejected.
        <% end %>
        ") if Template::SmsTemplate.where(name: "cancellation_request_rejected").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_created", content: "A swap has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing your request and will get in touch with you shortly.") if Template::SmsTemplate.where(name: "swap_request_created").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_resolved", content: "Swap request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed. We have now blocked <%= I18n.t('global.project_unit') %> <%= alternate_project_unit.name %> for you.") if Template::SmsTemplate.where(name: "swap_request_resolved").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_rejected", content: "Swap request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been rejected.") if Template::SmsTemplate.where(name: "swap_request_rejected").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_success", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> was successful (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "receipt_success").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_failed", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has failed (<%= receipt_id %>).") if Template::SmsTemplate.where(name: "receipt_failed").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_pending", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has been collected and will be sent to the <%= user.name %> Team for clearance.") if Template::SmsTemplate.where(name: "receipt_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_clearance_pending", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> is under 'Pending Clearance' (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "receipt_clearance_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "promote_future_payment_6", content: "Only 6 days to go! 6 days to being part of <%= project_unit.booking_portal_client.name %>. Click here to pay the pending amount of Rs. <%= project_unit.pending_balance %> for unit <%= name %> and secure your home at <%= project_unit.project_name %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_6").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "promote_future_payment_5", content: "A home, an identity - come home to yours. Only 5 days to go before you miss your home at <%= project_unit.project_name %>! Get it before you regret it. Click here to complete paying the pending amount: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_5").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "promote_future_payment_4", content: "You buy electronics online, you buy groceries online - why not a home? Complete your pending amount of Rs. <%= project_unit.pending_balance %> for unit <%= name %> at <%= project_unit.project_name %> on the portal, before you miss your home. You've got only 4 days to go! Click to pay: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_4").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "promote_future_payment_3", content: "A lot can happen in 3 days - today, you have a home at the prestigious <%= project_unit.booking_portal_client.name %> reserved in your name. 3 days from now, you could've missed that opportunity. Click here to pay the pending amount of Rs. <%= project_unit.pending_balance %> for unit <%= name %> today: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_3").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "promote_future_payment_2", content: "2 days to go! 2 days until you've missed your home at <%= project_unit.project_name %> - or, you could be the proud resident of <%= project_unit.booking_portal_client.name %> today. Click here to complete the transaction of Rs. <%= project_unit.pending_balance %> for unit <%= name %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_2").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "promote_future_payment_1", content: "Today's your last chance to call <%= name %> at <%= project_unit.project_name %> your home! Complete the payment today, or the apartment will get auto-released for other users to book it. Click here to complete your payment of Rs. <%= project_unit.pending_balance %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "promote_future_payment_1").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "daily_reminder_for_booking_payment", content: "You have booked your spot among the privileged few in <%= project_unit.project_name %>. Kindly pay the remaining balance to complete the booking process. The due date is just <%= I18n.l(project_unit.auto_release_on) %>. Visit <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "daily_reminder_for_booking_payment").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "project_unit_released", content: "Dear <%= name %>, you missed out! We regret to inform you that the apartment you shortlisted has been released. Click here if you'd like to re-start the process: <%= dashboard_url %> Your cust ref id is <%= lead_id %>") if Template::SmsTemplate.where(name: "project_unit_released").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "booking_blocked", content: "Congratulations <%= user.name %>, <%= name %> has been Blocked / Tentative Booked for you for the next <%= project_unit.blocking_days %> days! To own the home, you'll need to pay the pending amount of Rs. <%= project_unit.pending_balance %> within these <%= project_unit.blocking_days %> days. To complete the payment now, click here: <%= user.dashboard_url %>") if Template::SmsTemplate.where(name: "booking_blocked").blank?
      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "channel_partner_booking_blocked", content: "Dear <%= user.manager.name %>, <%= user.name %> has blocked unit <%= name %>.") if Template::SmsTemplate.where(name: "channel_partner_booking_blocked").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "booking_confirmed", content: "Welcome to the <%= project_unit.booking_portal_client.name %> family! You're now the proud owner of <%= name %> at <%= project_unit.project_name %> in <%= project_unit.booking_portal_client.name %>. Our executives will be in touch regarding agreement formalities.") if Template::SmsTemplate.where(name: "booking_confirmed").blank?
      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "channel_partner_booking_confirmed", content: "Dear <%= user.manager.name %>, <%= user.name %> has booked unit <%= name %>.") if Template::SmsTemplate.where(name: "channel_partner_booking_confirmed").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "user_registered_by_channel_partner", content: "<%= manager.name %> has registered you with <%= booking_portal_client.name %>. To confirm your account with this partner, please click <%= confirmation_url %>. You can also confirm your account using your phone & <%= I18n.t('global.otp') %>.") if Template::SmsTemplate.where(name: "user_registered_by_channel_partner").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "channel_partner_user_registered", content: "Dear <%= name %>, thank you for registering as a Channel Partner at <%= booking_portal_client.name %>. To confirm your account, please click <%= confirmation_url %>. You can also confirm your account using your phone & <%= I18n.t('global.otp') %>.") if Template::SmsTemplate.where(name: "channel_partner_user_registered").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "user_registered", content: "Dear <%= name %>, thank you for registering at <%= booking_portal_client.name %>. To confirm your account, please click <%= confirmation_url %>. You can also confirm your account using your phone & <%= I18n.t('global.otp') %>.") if Template::SmsTemplate.where(name: "user_registered").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Client", name: "daily_sms_report", content: 'Blocked: <%= ProjectUnit.where(status: "blocked").count %>. Tentative: <%= ProjectUnit.where(status: "booked_tentative").count %>. Confirmed: <%= ProjectUnit.where(status: "booked_confirmed").count %>. Blocked Today: <%= ProjectUnit.where(blocked_on: Date.today).count %>.     *subject to cancellations') if Template::SmsTemplate.where(name: "daily_sms_report").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Invitation", name: "referral_invitation", content: "Dear <%= self.name %>, You are invited in <%= self.booking_portal_client.booking_portal_domains.join(', ') %> Please click here. <%= Rails.application.routes.url_helpers.register_url(custom_referral_code: self.referred_by.referral_code) %> or user <%= self.referred_by.referral_code %> code for sign up.") if Template::SmsTemplate.where(name: "referral_invitation").blank?

      return Template::SmsTemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
