module DatabaseSeeds
  module EmailTemplates
    module Invoice
      def self.seed(project_id, client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_pending_approval", subject: "Invoice #<%= self.number %> for <%= self.invoiceable.name_in_invoice %> has been sent for approval", content: '
          <div class="card w-100">
            <div class="card-body">
              <p>
                <% url = Rails.application.routes.url_helpers %>
                Invoice #<a href="<%= url.admin_invoice_url(self) %>" target="_blank"><%= self.number %></a>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_pending_approval").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_approved", subject: "Invoice #<%= self.number %> for <%= self.invoiceable.name_in_invoice %> has been approved", content: '
          <div class="card w-100">
            <div class="card-body">
            <% url = Rails.application.routes.url_helpers %>
              <p>
                Invoice #<a href="<%= url.admin_invoice_url(self) %>" target="_blank"><%= self.number %></a> for <%= self.invoiceable.name_in_invoice %> is approved.
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_approved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_paid", subject: "Invoice #<%= self.number %> for <%= self.invoiceable.name_in_invoice %> has been paid", content: '
          <div class="card w-100">
            <div class="card-body">
            <% url = Rails.application.routes.url_helpers %>
              <p>
                Invoice #<%= self.number %> for <%= self.invoiceable.name_in_invoice %> is paid - Please find the payment details <a href="<%= url.admin_invoice_url(self) %>" target="_blank">here</a>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_paid").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_rejected", subject: "Invoice #<%= self.number %> for <%= self.invoiceable.name_in_invoice %> has been rejected", content: '
          <div class="card w-100">
            <div class="card-body">
            <% url = Rails.application.routes.url_helpers %>
              <p>
                Invoice #<a href="<%= url.admin_invoice_url(self) %>" target="_blank"><%= self.number %></a> for <%= self.invoiceable.name_in_invoice %> has been rejected with following reason:<br>
                <%= self.rejection_reason %>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_rejected").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_pending_approvals_list", subject: "Pending Invoices for approval", content: '
          <div class="card w-100">
            <div class="card-body">
              <p>
                Following invoices are pending to get approved -
              </p>
              <% url = Rails.application.routes.url_helpers %>
              <% invoices = Invoice.where(Invoice.user_based_scope(self)).where(status: "pending_approval") %>
              <table>
                <% invoices.each do |invoice| %>
                  <tr>
                    <td><%= invoice.invoiceable.name_in_invoice %></td>
                    <td><a href = "<%= url.admin_invoice_url(invoice) %>">link</a></td>
                  </tr>
                <% end %>
              </table>
            </div>
          </div>
          ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_pending_approvals_list").blank?
      end
    end
  end
end
