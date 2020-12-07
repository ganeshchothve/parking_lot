module DatabaseSeeds
  module EmailTemplates
    module Invoice
      def self.seed(client_id)
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Invoice", name: "invoice_pending_approval", subject: "Invoice for <%= self.booking_detail.name %> has been raised", content: '
          <div class="card w-100">
            <div class="card-body">
              <p>
                <% url = Rails.application.routes.url_helpers %>
                Invoice - <td><a href = "<%= url.admin_invoice_url(self) %>">link</a></td>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "invoice_pending_approval").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Invoice", name: "invoice_approved", subject: "Invoice for <%= self.booking_detail.name %> has been approved", content: '
          <div class="card w-100">
            <div class="card-body">
              <p>
                Invoice for <%= self.booking_detail.name %> is approved - <%= link_to "Invoice",  admin_invoice_path(self) %>
              </p>
            </div>
          </div>
        ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "invoice_approved").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "Invoice", name: "invoice_pending_approvals_list", subject: "Pending Invoices for approval", content: '
          <div class="card w-100">
            <div class="card-body">
              <p>
                Following invoices are pending to get approved -
              </p>
              <% url = Rails.application.routes.url_helpers %>
              <% invoices = Invoice.where(status: "pending_approval") %>
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
          ') if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: "invoice_pending_approvals_list").blank?
      end
    end
  end
end
