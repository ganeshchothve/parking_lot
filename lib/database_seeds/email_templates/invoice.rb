module DatabaseSeeds
  module EmailTemplates
    module Invoice
      def self.seed(project_id, client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_pending_approval", subject: "Invoice #<%= self.number %> for <%= self.booking_detail.name %> has been sent for approval", content: '
          <div class="card w-100">
            <div class="card-body">
              <p>
                <% url = Rails.application.routes.url_helpers %>
                Invoice #<%= self.number %> - <td><a href="<%= url.admin_invoice_url(self) %>">link</a></td>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_pending_approval").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_approved", subject: "Invoice #<%= self.number %> for <%= self.booking_detail.name %> has been approved", content: '
          <div class="card w-100">
            <div class="card-body">
            <% url = Rails.application.routes.url_helpers %>
              <p>
                Invoice #<%= self.number %> for <%= self.booking_detail.name %> is approved - <%= link_to "Invoice", url.admin_invoice_path(self) %>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_approved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_paid", subject: "Invoice #<%= self.number %> for <%= self.booking_detail.name %> has been paid", content: '
          <div class="card w-100">
            <div class="card-body">
            <% url = Rails.application.routes.url_helpers %>
              <p>
                Invoice #<%= self.number %> for <%= self.booking_detail.name %> is paid - Please find the payment details <%= link_to "here", url.admin_invoice_path(self) %>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: "invoice_paid").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: "Invoice", name: "invoice_rejected", subject: "Invoice #<%= self.number %> for <%= self.booking_detail.name %> has been rejected", content: '
          <div class="card w-100">
            <div class="card-body">
            <% url = Rails.application.routes.url_helpers %>
              <p>
                Invoice #<%= link_to self.number, url.admin_invoice_path(self) %> for <%= self.booking_detail.name %> has been rejected with following reason:<br>
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
              <% invoices = Invoice.where(Invoice.user_based_scope(self)).where(status: "pending_approval", raised_date: {"$lt": Date.today-self.booking_portal_client.invoice_approval_tat } ) %>
              <table>
                <% invoices.each do |invoice| %>
                  <tr>
                    <td><%= invoice.booking_detail.name %></td>
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
