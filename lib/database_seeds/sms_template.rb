# DatabaseSeeds::SmsTemplate.seed CLient.last.id
module DatabaseSeeds
  module SmsTemplate
    def self.project_based_sms_templates_seed(project_id, client_id)
      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "UserRequest::Cancellation", name: "cancellation_request_pending", content: "
        <% if requestable.kind_of?(BookingDetail) %>
          A cancellation has been requested on your booking of <%= requestable.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing your request and will get in touch with you shortly.
        <% elsif requestable.kind_of?(Receipt) %>
          A cancellation has been requested on your payment of <%= requestable.name %> . Our CRM team is reviewing your request and will get in touch with you shortly.
        <% end %>"
        ) if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "cancellation_request_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "UserRequest::Cancellation", name: "cancellation_request_resolved", content: "
        <% if requestable.kind_of?(BookingDetail) %>
          We're sorry to see you go. Cancellation request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed and your amount will be refunded to you in a few days. To book another unit visit <%= user.dashboard_url %>
        <% elsif requestable.kind_of?(Receipt) %>
          We're sorry to see you go. Cancellation request on your payment <%= requestable.name %> has been processed and your amount will be refunded to you in a few days.
        <% end %>
          ") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "cancellation_request_resolved").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "UserRequest::Cancellation", name: "cancellation_request_rejected", content: "
        <% if requestable.kind_of?(BookingDetail) %>
        Cancellation request on your booking of <%= requestable.name %> at <%= project_unit.project_name %> has been rejected.
        <% elsif requestable.kind_of?(Receipt) %>
          Cancellation request on your payment <%= requestable.name %> has been rejected.
        <% end %>
        ") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "cancellation_request_rejected").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Invoice", name: "invoice_pending_approval", content: "Invoice for <%= self.invoiceable.name_in_invoice %> has been raised") if Template::SmsTemplate.where(name: "invoice_pending_approval", project_id: project_id).blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Invoice", name: "invoice_approved", content: "Invoice for <%= self.invoiceable.name_in_invoice %> has been approved") if Template::SmsTemplate.where(name: "invoice_approved", project_id: project_id).blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "UserRequest::Swap", name: "swap_request_created", content: "A swap has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing your request and will get in touch with you shortly.") if Template::SmsTemplate.where(project_id: project_id, name: "swap_request_created").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "UserRequest::Swap", name: "swap_request_resolved", content: "Swap request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed. We have now blocked <%= I18n.t('global.tabs.project_unit') %> <%= alternate_project_unit.name %> for you.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "swap_request_resolved").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "UserRequest::Swap", name: "swap_request_rejected", content: "Swap request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been rejected.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "swap_request_rejected").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "receipt_success", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> was successful (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_success").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "receipt_failed", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has failed (<%= receipt_id %>).") if Template::SmsTemplate.where(project_id: project_id, name: "receipt_failed").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "receipt_pending", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has been collected and will be sent to the <%= user.name %> Team for clearance.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "receipt_clearance_pending", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> is under 'Pending Clearance' (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_clearance_pending").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "receipt_available_for_refund", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> is under 'Available For Refund' (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_available_for_refund").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "receipt_refunded", content: "Dear <%= user.name %>, your payment (<%= receipt_id %>) of Rs. <%= total_amount %> has been refunded. To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_refunded").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "promote_future_payment_6", content: "Only 6 days to go! 6 days to being part of <%= project_unit.booking_portal_client.name %>. Click here to pay the pending amount of Rs. <%= project_unit.pending_balance %> for unit <%= name %> and secure your home at <%= project_unit.project_name %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "promote_future_payment_6").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "promote_future_payment_5", content: "A home, an identity - come home to yours. Only 5 days to go before you miss your home at <%= project_unit.project_name %>! Get it before you regret it. Click here to complete paying the pending amount: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "promote_future_payment_5").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "promote_future_payment_4", content: "You buy electronics online, you buy groceries online - why not a home? Complete your pending amount of Rs. <%= project_unit.pending_balance %> for unit <%= name %> at <%= project_unit.project_name %> on the portal, before you miss your home. You've got only 4 days to go! Click to pay: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "promote_future_payment_4").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "promote_future_payment_3", content: "A lot can happen in 3 days - today, you have a home at the prestigious <%= project_unit.booking_portal_client.name %> reserved in your name. 3 days from now, you could've missed that opportunity. Click here to pay the pending amount of Rs. <%= project_unit.pending_balance %> for unit <%= name %> today: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "promote_future_payment_3").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "promote_future_payment_2", content: "2 days to go! 2 days until you've missed your home at <%= project_unit.project_name %> - or, you could be the proud resident of <%= project_unit.booking_portal_client.name %> today. Click here to complete the transaction of Rs. <%= project_unit.pending_balance %> for unit <%= name %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "promote_future_payment_2").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "promote_future_payment_1", content: "Today's your last chance to call <%= name %> at <%= project_unit.project_name %> your home! Complete the payment today, or the apartment will get auto-released for other users to book it. Click here to complete your payment of Rs. <%= project_unit.pending_balance %>: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "promote_future_payment_1").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "daily_reminder_for_booking_payment", content: "You have booked your spot among the privileged few in <%= project_unit.project_name %>. Kindly pay the remaining balance to complete the booking process. The due date is just <%= I18n.l(project_unit.auto_release_on) %>. Visit <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "daily_reminder_for_booking_payment").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "booking_blocked", content: "Congratulations <%= user.name %>, <%= name %> has been Blocked / Tentative Booked for you for the next <%= project_unit.blocking_days %> days! To own the home, you'll need to pay the pending amount of Rs. <%= project_unit.pending_balance %> within these <%= project_unit.blocking_days %> days. To complete the payment now, click here: <%= user.dashboard_url %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "booking_blocked").blank?
      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "channel_partner_booking_blocked", content: "Dear <%= user.manager.name %>, <%= user.name %> has blocked unit <%= name %>.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "channel_partner_booking_blocked").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "booking_confirmed", content: "Welcome to the <%= project_unit.booking_portal_client.name %> family! You're now the proud owner of <%= name %> at <%= project_unit.project_name %> in <%= project_unit.booking_portal_client.name %>. Our executives will be in touch regarding agreement formalities.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "booking_confirmed").blank?
      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "BookingDetail", name: "channel_partner_booking_confirmed", content: "Dear <%= user.manager.name %>, <%= user.name %> has booked unit <%= name %>.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id,name: "channel_partner_booking_confirmed").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id,  subject_class: "Receipt", name: "daily_payments_report", content: '[<%= Date.current.strftime("%v") %>] Today you received <%= self.class.todays_payments_count(project_id) %> payments for project <%= receipt.project.name %>') if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "daily_payments_report").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_payment_hour_1', content: "Alert: Your KYC registration is not yet complete. Complete payment to lock your spot in the queue and avail unique benefits, call <%= self.booking_portal_client.support_number %> for more information.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_payment_hour_1").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_payment_day_1', content: "Reminder: Your KYC registration is not yet complete. Lock your spot in the queue and avail unique benefits, call <%= self.booking_portal_client.support_number %> for more information.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_payment_day_1").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_payment_day_3', content: "Reminder: You are one step away from booking your spot, call on <%= self.booking_portal_client.support_number %> for more information.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_payment_day_3").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_booking_day_4', content: "In case if you need a home loan, select loan preference and upload KYC so that our loan representative can help you.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_booking_day_4").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_booking_day_5', content: "Earn additional discounts at <%= booking_portal_client.name %> by completing your profile to help us know you better.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_booking_day_5").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_booking_day_6', content: "Thank for showing your preference for the loan requirement for your dream home at <%= booking_portal_client.name %>. We have a host financial partners who are offering home loans at competitive rates.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_booking_day_6").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "User", name: 'no_booking_day_7', content: "Earn additional discounts by referring your 3 friends at <%= booking_portal_client.name %>.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "no_booking_day_7").blank?

      # TODO : : Discus how to handle lead id.
      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: "project_unit_released", content: "Dear <%= self.user.name %>, you missed out! We regret to inform you that the apartment you shortlisted from project <%= self.project.try(:name) %> has been released. Click here if you'd like to re-start the process: <%= dashboard_url %> Your cust ref id is <%= self.user.lead_id %>") if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "project_unit_released").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Project", name: "daily_sms_report", content: 'Daily SMS Report for the project <%= self.name %> => Blocked: <%= self.booking_details.where(status: "blocked").count %>. Tentative: <%= self.booking_details.where(status: "booked_tentative").count %>. Confirmed: <%= self.booking_details.where(status: "booked_confirmed").count %>. Blocked Today: <%= self.project_units.where(blocked_on: Date.today).count %>') if Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "daily_sms_report").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: 'payment_link', content: 'Dear <%= self.name %>, Thank you for your interest in <%= self.project.try(:name) %>. To make your first payment, please click here: <%= short_url(self.payment_link, self.try(:booking_portal_client_id).try(:to_s)), true %>')  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "payment_link", project_id: project_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Lead", name: 'queue_number_notice', content: 'Your queue_number is <%= self.queue_number %>') if ::Template::SmsTemplate.where(name: "queue_number_notice", project_id: project_id, booking_portal_client_id: client_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: 'site_visit_scheduled', content: 'Your site visit is scheduled on <%= I18n.l(scheduled_on) %> for <%= project.name %>') if ::Template::SmsTemplate.where(name: "site_visit_scheduled", project_id: project_id, booking_portal_client_id: client_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: 'site_visit_conducted', content: 'Your site visit for <%= project.name %> was successfully conducted') if ::Template::SmsTemplate.where(name: "site_visit_conducted", project_id: project_id, booking_portal_client_id: client_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: 'site_visit_cancelled', content: 'Your site visit scheduled on <%= I18n.l(scheduled_on) %> for <%= project.name %> is cancelled') if ::Template::SmsTemplate.where(name: "site_visit_cancelled", project_id: project_id, booking_portal_client_id: client_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: 'site_visit_inactive', content: 'Your site visit scheduled on <%= I18n.l(scheduled_on) %> for <%= project.name %> has been marked inactive. Please schedule a new visit') if ::Template::SmsTemplate.where(name: "site_visit_inactive", project_id: project_id, booking_portal_client_id: client_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "SiteVisit", name: 'site_visit_rescheduled', content: 'Your site visit is rescheduled on <%= I18n.l(scheduled_on) %> for <%= project.name %>') if ::Template::SmsTemplate.where(name: "site_visit_rescheduled", project_id: project_id, booking_portal_client_id: client_id).blank?

      return Template::SmsTemplate.where(booking_portal_client_id: client_id, project_id: project_id).count
    end

    def self.client_based_sms_templates_seed client_id
      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "user_registered_by_channel_partner", content: "<%= manager.name %> has registered you with <%= booking_portal_client.name %>. To confirm your account with this partner, please click <%= confirmation_url %>. You can also confirm your account using your phone & <%= I18n.t('global.otp') %>.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "user_registered_by_channel_partner").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "channel_partner_user_registered", content: "Dear <%= name %>, thank you for registering as a Channel Partner at <%= booking_portal_client.name %>. To confirm your account, please click <%= confirmation_url %>. You can also confirm your account using your phone & <%= I18n.t('global.otp') %>.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "channel_partner_user_registered").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "User", name: "user_registered", content: "Dear <%= name %>, thank you for registering at <%= booking_portal_client.name %>. To confirm your account, please click <%= confirmation_url %>. You can also confirm your account using your phone & <%= I18n.t('global.otp') %>.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "user_registered").blank?

      Template::SmsTemplate.create({booking_portal_client_id: client_id, subject_class: "User", name: "otp", content: "Your <%= I18n.t('global.otp') %> for logging into <%= booking_portal_client.name %> is <%= otp_code %>."})  if Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "otp").blank?


      # reminder templates
      Template::SmsTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'not_confirmed_day_1', content: "Thank you for your interest in <%= booking_portal_client.name %>. Your KYC generation is not complete. For more information about the project, call <%= self.booking_portal_client.support_number %>")   if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "not_confirmed_day_1").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'not_confirmed_day_3', content: "Don’t be late! <%= booking_portal_client.name %> is offering rewards on a first come first serve basis. Register today and avail special benefits, call <%= self.booking_portal_client.support_number %> for more information.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "not_confirmed_day_3").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'not_confirmed_day_5', content: "You are doing your best to build your kids’ dream home. We are doing our best to make it a reality. Register today and get greater discounts, call <%= self.booking_portal_client.support_number %> for more information.")  if ::Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "not_confirmed_day_5").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Invitation", name: "referral_invitation", content: "Dear <%= self.name %>, You are invited in <%= self.booking_portal_client.booking_portal_domains.join(', ') %> Please click here. <%= Rails.application.routes.url_helpers.register_url(custom_referral_code: self.referred_by.referral_code) %> or user <%= self.referred_by.referral_code %> code for sign up.") if Template::SmsTemplate.where(booking_portal_client_id: client_id, name: "referral_invitation").blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, subject_class: "Lead", name: "send_tp_projects_link", content: 'Dear <%= lead.name %>, Please check out these new projects:
      <% url = "#{@project_url}?#{@project_ids.collect {|x| \'search[project_ids][]=\' + x}.join(\'&\')}" %>
      <%= short_url(url, lead.booking_portal_client_id.to_s) %>') if ::Template::SmsTemplate.where(name: "send_tp_projects_link", booking_portal_client_id: client_id).blank?

      Template::SmsTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: "cp_user_register_in_company", content: '
          Dear <%= temp_channel_partner&.primary_user&.name || "Sir/Madam" %>,
          <%= name %> has requested to register his account into your company on <%= I18n.t("global.brand", client_name: self.booking_portal_client.name) %>.
              Please use the following link to approve his/her account to give him/her access as a <%= I18n.t("mongoid.attributes.user/role.channel_partner") %> into your company.
              <% url = "#{Rails.application.routes.url_helpers.add_user_account_channel_partners_url(register_code: self.register_in_cp_company_token, channel_partner_id: self.temp_channel_partner&.id.to_s, host: self.booking_portal_client.base_domain)}" %>
              <%= short_url(url, self.booking_portal_client_id.to_s) %>') if ::Template::SmsTemplate.where(name: "cp_user_register_in_company").blank?


      Template::SmsTemplate.create!(booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "second_booking_notification", content: 'Alert - Channel Partner <%= self.manager.try(:name) %> has added more than 1 booking on same customer <%= self.lead.try(:name) %> for project <%= self.try(:project).try(:name) %> on <%= self.booking_portal_client.name %> portal. Please cross verify with channel Partner / channel partner manager before approval.') if ::Template::SmsTemplate.where(name: "second_booking_notification").blank?

      Template::SmsTemplate.create(booking_portal_client_id: client_id, subject_class: "Receipt", name: "updated_token_details", content: "Dear <%= user.name %>, your token has been updated") if Template::SmsTemplate.where(name: "updated_token_details").blank?


      return Template::SmsTemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
