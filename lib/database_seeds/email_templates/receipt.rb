module DatabaseSeeds
  module EmailTemplates
    module Receipt
      def self.seed(project_id, client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Receipt", name: "receipt_success", subject: "Payment <%= self.receipt_id %> Successful", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              <% if self.blocking_payment? %>
                Welcome to <%= self.project.name %>. Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>. We will contact you shortly to discuss the next round of formalities.
              <% else %>
                Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>. We are happy to inform that your payment has cleared. We will contact you shortly to discuss the next round of formalities.
              <% end %>
            </p>
          </div>
        </div>
        <div class="mt-3"></div>
        <%= booking_portal_client.templates.where(_type: "Template::ReceiptTemplate", project_id: self.project_id).first.parsed_content(self) %>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_success").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Receipt", name: "receipt_failed", subject: "Payment <%= self.receipt_id %> Failed", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              <p>
                <% if self.payment_mode == "online" %>
                  Your online payment of <%= number_to_indian_currency(self.total_amount) %> failed. We request you to re-attempt your payment. For any other mode of payment, please get in touch with our team for further details.
                <% else %>
                  Your payment of <%= number_to_indian_currency(self.total_amount) %> was dishonoured by your bank. Please check with them regarding your payment. We request you to re-issue a different <%= I18n.t("mongoid.attributes.receipt/payment_mode.#{self.payment_mode}") %>payment.
                <% end %>
              </p>
            </div>
          </div>
          <div class="mt-3"></div>
          <%= booking_portal_client.templates.where(_type: "Template::ReceiptTemplate", project_id: self.project_id).first.parsed_content(self) %>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_failed").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Receipt", name: "receipt_clearance_pending", subject: "Payment <%= self.receipt_id %> is pending clearance", content: '<div class="card w-100">
          <div class="card-body">
            <p>Dear <%= self.user.name %>,</p>
            <p>
              Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>. We have processed your payment and are waiting for it to be cleared.
            </p>
          </div>
        </div>
        <div class="mt-3"></div>
        <%= booking_portal_client.templates.where(_type: "Template::ReceiptTemplate", project_id: self.project_id).first.parsed_content(self) %>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_clearance_pending").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Receipt", name: "receipt_pending", subject: "Payment Receipt <%= self.receipt_id %> Collected", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              <p>Thank you for your payment of <%= number_to_indian_currency(self.total_amount) %>.</p>
            </div>
          </div>
          <div class="mt-3"></div>
          <%= booking_portal_client.templates.where(_type: "Template::ReceiptTemplate", project_id: self.project_id).first.parsed_content(self) %>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_pending").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Receipt", name: "receipt_refunded", subject: "Your refund for payment <%= self.receipt_id %> has been processed", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              <p>Your refund for payment <%= self.receipt_id %> has been processed.</p>
              <p>Amount: <%= number_to_indian_currency(self.total_amount) %>.</p>
            </div>
          </div>
          <div class="mt-3"></div>
          <%= booking_portal_client.templates.where(_type: "Template::ReceiptTemplate", project_id: self.project_id).first.parsed_content(self) %>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_refunded").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Receipt", name: "receipt_available_for_refund", subject: "Your payment <%= self.receipt_id %> is available for refund.", content: '<div class="card w-100">
            <div class="card-body">
              <p>Dear <%= self.user.name %>,</p>
              <p>Your refund for payment <%= self.receipt_id %> has been processed.</p>
              <p>AYour payment <%= self.receipt_id %> is available for refund.</p>
            </div>
          </div>
          <div class="mt-3"></div>
          <%= booking_portal_client.templates.where(_type: "Template::ReceiptTemplate", project_id: self.project_id).first.parsed_content(self) %>') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "receipt_available_for_refund").blank?

      end
    end
  end
end
