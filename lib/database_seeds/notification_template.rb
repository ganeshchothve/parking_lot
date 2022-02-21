# DatabaseSeeds::NotificationTemplate.seed Client.last.id, project_id
module DatabaseSeeds
  module NotificationTemplate
    def self.seed(client_id, project_id)

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", title: "Cancellation request pending", url: "/<%= current_user_role_group %>/all/user_requests", name: "cancellation_request_pending", content: "
        <% if requestable.kind_of?(BookingDetail) %>
          A cancellation has been requested on your booking of <%= requestable.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing your request and will get in touch with you shortly.
        <% elsif requestable.kind_of?(Receipt) %>
          A cancellation has been requested on your payment of <%= requestable.name %> . Our CRM team is reviewing your request and will get in touch with you shortly.
        <% end %>"
        ) if Template::NotificationTemplate.where(name: "cancellation_request_pending", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_resolved", title: "Cancellation request resolved", url: "/<%= current_user_role_group %>/all/user_requests", content: "
        <% if requestable.kind_of?(BookingDetail) %>
          We're sorry to see you go. Cancellation request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed and your amount will be refunded to you in a few days. To book another unit visit <%= user.dashboard_url %>
        <% elsif requestable.kind_of?(Receipt) %>
          We're sorry to see you go. Cancellation request on your payment <%= requestable.name %> has been processed and your amount will be refunded to you in a few days.
        <% end %>
      ") if Template::NotificationTemplate.where(name: "cancellation_request_resolved", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "UserRequest::Cancellation", name: "cancellation_request_rejected",  title: "Cancellation request rejected", url: "/<%= current_user_role_group %>/all/user_requests", content: "
        <% if requestable.kind_of?(BookingDetail) %>
        Cancellation request on your booking of <%= requestable.name %> at <%= project_unit.project_name %> has been rejected.
        <% elsif requestable.kind_of?(Receipt) %>
          Cancellation request on your payment <%= requestable.name %> has been rejected.
        <% end %>
        ") if Template::NotificationTemplate.where(name: "cancellation_request_rejected", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_pending", title: "Swap request pending", url: "/<%= current_user_role_group %>/all/user_requests", content: "A swap has been requested on your booking of <%= project_unit.name %> at <%= project_unit.project_name %>. Our CRM team is reviewing your request and will get in touch with you shortly.") if Template::NotificationTemplate.where(name: "swap_request_pending", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_resolved",  title: "Swap request resolved", url: "/<%= current_user_role_group %>/all/user_requests", content: "Swap request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been processed. We have now blocked <%= I18n.t('global.project_unit') %> <%= alternate_project_unit.name %> for you.") if Template::NotificationTemplate.where(name: "swap_request_resolved", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "UserRequest::Swap", name: "swap_request_rejected", title: "Swap request rejected", url: "/<%= current_user_role_group %>/all/user_requests", content: "Swap request on your booking of <%= project_unit.name %> at <%= project_unit.project_name %> has been rejected.") if Template::NotificationTemplate.where(name: "swap_request_rejected", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_success", title: "Payment Successful", url: "/<%= current_user_role_group %>/receipts", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> was successful (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::NotificationTemplate.where(name: "receipt_success", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_failed", title: "Payment failed", url: "/<%= current_user_role_group %>/receipts", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has failed (<%= receipt_id %>).") if Template::NotificationTemplate.where(name: "receipt_failed", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_pending", title: "Payment pending", url: "/<%= current_user_role_group %>/receipts", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> has been collected and will be sent to the <%= user.name %> Team for clearance.") if Template::NotificationTemplate.where(name: "receipt_pending", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_clearance_pending",  title: "Payment clearance pending", url: "/<%= current_user_role_group %>/receipts", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> is under 'Pending Clearance' (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::NotificationTemplate.where(name: "receipt_clearance_pending", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_available_for_refund", title: "Payment available for refund", url: "/<%= current_user_role_group %>/receipts", content: "Dear <%= user.name %>, your payment of Rs. <%= total_amount %> is under 'Available For Refund' (<%= receipt_id %>). To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::NotificationTemplate.where(name: "receipt_available_for_refund", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_refunded", title: "Payment refunded", url: "/<%= current_user_role_group %>/receipts", content: "Dear <%= user.name %>, your payment (<%= receipt_id %>) of Rs. <%= total_amount %> has been refunded. To view your receipt visit your Portal Dashboard <%= user.dashboard_url %>") if Template::NotificationTemplate.where(name: "receipt_refunded", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "booking_blocked", title: "Project Unit has been blocked", url: "/<%= current_user_role_group %>/booking_details/<%= id.to_s %>", content: "Congratulations <%= user.name %>, <%= name %> has been Blocked / Tentative Booked for you for the next <%= project_unit.blocking_days %> days! To own the home, you'll need to pay the pending amount of Rs. <%= project_unit.pending_balance %> within these <%= project_unit.blocking_days %> days. To complete the payment now, click here: <%= user.dashboard_url %>") if Template::NotificationTemplate.where(name: "booking_blocked", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id,booking_portal_client_id: client_id, subject_class: "BookingDetail", name: "booking_confirmed", title: "Booking confirmed", url: "/<%= current_user_role_group %>/booking_details/<%= id.to_s %>", content: "Welcome to the <%= project_unit.booking_portal_client.name %> family! You're now the proud owner of <%= name %> at <%= project_unit.project_name %> in <%= project_unit.booking_portal_client.name %>. Our executives will be in touch regarding agreement formalities.") if Template::NotificationTemplate.where(name: "booking_confirmed", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "ChannelPartner", name: "channel_partner_status_active", title: "Account has been approved", url: "/", content: "You account has been approved.") if Template::NotificationTemplate.where(name: "channel_partner_status_active", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "ChannelPartner", name: "channel_partner_status_rejected", title: "Account has been rejected", url: "/", content: "You account has been rejected for following reason - <%= self.try(:status_change_reason) %>") if Template::NotificationTemplate.where(name: "channel_partner_status_rejected", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "User", name: "user_status_active_in_company", title: "Account has been approved", url: "/", content: "You account has been approved.") if Template::NotificationTemplate.where(name: "user_status_active_in_company", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "User", name: "user_status_inactive_in_company", title: "Account has been rejected", url: "/", content: "You account has been rejected for following reason - <%= self.try(:status_change_reason) %>") if Template::NotificationTemplate.where(name: "user_status_inactive_in_company", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Sitevisit", name: "site_visit_approval_status_rejected_notification", title: "Sitevisit rejected", url: "/", content: "Rejected") if Template::NotificationTemplate.where(name: "site_visit_approval_status_rejected_notification", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Sitevisit", name: "site_visit_approval_status_approved_notification", title: "Sitevisit approved", url: "/", content: "Approved") if Template::NotificationTemplate.where(name: "site_visit_approval_status_approved_notification", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Sitevisit", name: "site_visit_status_paid_notification", title: "Sitevisit paid", url: "/", content: "Paid") if Template::NotificationTemplate.where(name: "site_visit_status_paid_notification", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Invoice", name: "invoice_rejected", title: "Invoice rejected", url: "/", content: "Rejected") if Template::NotificationTemplate.where(name: "invoice_rejected", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Invoice", name: "invoice_approved", title: "Invoice approved", url: "/", content: "Approved") if Template::NotificationTemplate.where(name: "invoice_approved", project_id: project_id).blank?

      Template::NotificationTemplate.create(project_id: project_id, booking_portal_client_id: client_id, subject_class: "Invoice", name: "invoice_paid", title: "Invoice paid", url: "/", content: "Paid") if Template::NotificationTemplate.where(name: "invoice_paid", project_id: project_id).blank?

      return Template::NotificationTemplate.where(booking_portal_client_id: client_id).count
    end
  end
end
