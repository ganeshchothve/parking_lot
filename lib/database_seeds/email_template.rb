module DatabaseSeeds
  module EmailTemplate
    def self.seed client_id
      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_success", subject: "Test", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              <% if self.payment_type == "blocking" %>
                Welcome to <%= current_project.name %>. Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>. We will contact you shortly to discuss the next round of formalities.
              <% else %>
                Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>. We are happy to inform that your payment has cleared. We will contact you shortly to discuss the next round of formalities.
              <% end %>
            </p>
          </div>
        </div>
        <div class="mt-3"></div>
        <%= current_client.templates.where(_type: "Template::ReceiptTemplate").first.parsed_content(self) %>') if ::Template::EmailTemplate.where(name: "receipt_success").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Receipt", name: "receipt_failed", subject: "Test", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              <% if self.payment_mode == "online" %>
                Your online payment of <%= number_to_indian_currency(self.total_amount) %> failed. We request you to re-attempt your payment. For any other mode of payment, please get in touch with our team for further details.
              <% else %>
                Your payment of <%= number_to_indian_currency(self.total_amount) %> was dishonoured by your bank. Please check with them regarding your payment. We request you to re-issue a different <%= Receipt.available_payment_modes.find{|x| x[:id] == self.payment_mode}[:text] %> payment.
              <% end %>
            </p>
          </div>
        </div>
        <div class="mt-3"></div>
        <%= current_client.templates.where(_type: "Template::ReceiptTemplate").first.parsed_content(self) %>') if ::Template::EmailTemplate.where(name: "receipt_failed").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "receipt_clearance_pending", subject: "Test", content: '<div class="card w-100">
        <div class="card-body">
          <p>Dear <%= self.user.name %>,</p>
          <p>
            Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>. We have processed your payment and are waiting for it to be cleared.
          </p>
        </div>
      </div>
      <div class="mt-3"></div>
      <%= current_client.templates.where(_type: "Template::ReceiptTemplate").first.parsed_content(self) %>') if ::Template::EmailTemplate.where(name: "receipt_clearance_pending").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "project_unit_pending_offline", subject: "Test", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>.</p>
          </div>
        </div>
        <div class="mt-3"></div>
        <%= current_client.templates.where(_type: "Template::ReceiptTemplate").first.parsed_content(self) %>') if ::Template::EmailTemplate.where(name: "project_unit_pending_offline").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "project_unit_released", subject: "Test", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            Your Unit - <%= self.name %> has been released.<br/><br/>
            In case you need any assistance, please get in touch with our support team.
          </div>
        </div>
        <div class="mt-3"></div>
        <%= render "dashboard/project_unit_overview", project_unit: self %>
        <div class="mt-3"></div>
        <%= render "dashboard/project_unit_cost_sheet", project_unit: self %>
        <div class="mt-3"></div>
        <%= render "dashboard/project_unit_payment_schedule", project_unit: self %>') if ::Template::EmailTemplate.where(name: "project_unit_released").blank?


      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "project_unit_blocked", subject: "Test", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Welcome to <%= current_project.name %>, <%= current_project.description %>.
            </p>
            <p>
              We are pleased to inform that you are among the esteemed circle of customers who have booked an apartment at <%= current_project.name %>
            </p>
          </div>
        </div>
        <div class="mt-3"></div>
        <%= render "dashboard/project_unit_overview", project_unit: self %>
        <div class="mt-3"></div>
        <%= render "dashboard/project_unit_cost_sheet", project_unit: self %>
        <div class="mt-3"></div>
        <%= render "dashboard/project_unit_payment_schedule", project_unit: self %>
        <div class="mt-3"></div>
        <div class="card w-100">
          <div class="card-body">
            This unit will remain blocked for you for the next <%= self.blocking_days %> days. Please complete your payment of remaining amount within this duration to confirm your unit. To make additional payment please click <%= link_to "here", dashboard_url %>.
            <br/><br/>
            Your KYC details are incomplete, to complete your registration you can update them <%= link_to "here", user_user_kycs_url %>.<br/><br/>
            Welcome once again and do share with us your views and feedback.
          </div>
        </div>') if ::Template::EmailTemplate.where(name: "project_unit_blocked").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "project_unit_booked_tentative", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "project_unit_booked_tentative").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "project_unit_booked_confirmed", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "project_unit_booked_confirmed").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "auto_release_on_extended", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "auto_release_on_extended").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "user_kyc_added", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "user_kyc_added").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_created", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "cancellation_request_created").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_resolved", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "cancellation_request_resolved").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "cancellation_request_swapped", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "cancellation_request_swapped").blank?

      Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "UserRequest", name: "daily_reminder_for_booking_payment", subject: "Test", content: '') if ::Template::EmailTemplate.where(name: "daily_reminder_for_booking_payment").blank?
    end
  end
end
