class Template::ReceiptTemplate < Template
  def self.default_content
    '<div class="box-card">
       <div class="box-header bg-gradient br-rd-tr-4 text-center">
         <h2><strong>Payment Details</strong></h2>
         <% labels = I18n.t("mongoid.attributes.receipt").with_indifferent_access %>
       </div>
       <div class="box-content br-rd-bl-4 bg-white p-0">
         <table class="table my-customer-table responsive-tbl">
          <tbody>
            <tr>
              <td><%= labels["receipt_id"] %></td>
              <td class="text-right"><%= self.receipt_id %></td>
            </tr>
            <% if self.booking_detail_id.present? %>
            <tr>
              <td>Towards <%= labels["project_unit_id"] %></td>
              <td class="text-right"><%= self.booking_detail.name %></td>
            </tr>
            <% end %>
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
                <td class="text-right"><%= self.issued_date.strftime("%d/%m/%Y") %></td>
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
         <div class="text-muted small px-3 pb-3">Please note that cheque / RTGS / NEFT payments are subject to clearance</div>
         <% if self.booking_portal_client.try(:disclaimer).present? %>
          <div class="text-muted small px-3 pb-3">
            <strong>Disclaimer:</strong><br/>
            <%= self.booking_portal_client.disclaimer %>
          </div>
         <% end %>
       </div>
     </div>
     <div class="box-card mt-3">
       <div class="box-header bg-gradient br-rd-tr-4 text-center">
         <h2><strong>Token Details</strong></h2>
       </div>
       <div class="box-content br-rd-bl-4 bg-white p-0">
         <table class="table my-customer-table responsive-tbl">
           <tbody>
             <tr>
               <td>Token Number</td>
               <td class="text-right"><%= self.try(:token_number) ? self.get_token_number : "--" %></td>
             </tr>
             <% if project.enable_slot_generation? && self.try(:time_slot) %>
               <tr>
                 <td>Time Slot</td>
                 <td class="text-right"><%= self.time_slot.to_s(user.time_zone) %></td>
               </tr>
               <tr>
                 <td>Time Zone</td>
                 <td class="text-right"><%= self.user.time_zone %></td>
               </tr>
             <% end %>
           </tbody>
         </table>
       </div>
     </div>'
  end
end
