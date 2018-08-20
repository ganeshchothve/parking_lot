class Template::ReceiptTemplate < Template
  def self.default_content
    '<div class="card">
      <div class="card-body">
        <h5 class="text-center"><strong>Payment Details</strong></h5>
        <% labels = I18n.t("mongoid.attributes.receipt").with_indifferent_access %>
        <table class="table table-striped table-sm mt-3">
          <tbody>
            <tr>
              <td><%= labels["receipt_id"] %></td>
              <td class="text-right"><%= self.receipt_id %></td>
            </tr>
            <tr>
              <td><%= labels["payment_mode"] %></td>
              <td class="text-right"><%= self.class.available_payment_modes.find{|x| x[:id] == self.payment_mode}[:text] %></td>
            </tr>
            <% if self.payment_mode != "online" %>
              <tr>
                <td><%= labels["issuing_bank"] %></td>
                <td class="text-right"><%= self.issuing_bank %></td>
              </tr>
              <tr>
                <td><%= labels["issuing_bank_branch"] %></td>
                <td class="text-right"><%= self.issuing_bank_branch %></td>
              </tr>
              <tr>
                <td><%= labels["issued_date"] %></td>
                <td class="text-right"><%= self.issued_date %></td>
              </tr>
            <% end %>
            <tr>
              <td><%= labels["payment_identifier"] %></td>
              <td class="text-right"><%= self.payment_identifier %></td>
            </tr>
            <tr>
              <td><%= labels["status"] %></td>
              <td class="text-right"><%= self.status.titleize %></td>
            </tr>
            <tr>
              <td><%= labels["processed_on"] %></td>
              <td class="text-right"><%= self.processed_on.present? ? I18n.l(self.processed_on) : "-" %></td>
            </tr>
            <tr>
              <td><%= labels["total_amount"] %></td>
              <td class="text-right"><%= number_to_indian_currency(self.total_amount) %></td>
            </tr>
          </tbody>
        </table>
        <div class="mt-3 text-muted small">Please note that cheque / RTGS / NEFT payments are subject to clearance</div>
        <% if self.booking_portal_client.disclaimer.present? %>
          <div class="mt-3 text-muted small">
            <strong>Disclaimer:</strong><br/>
            <%= self.booking_portal_client.disclaimer %>
          </div>
        <% end %>
      </div>
    </div>'
  end
end
