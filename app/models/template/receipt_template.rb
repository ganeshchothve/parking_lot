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
         <div class="mt-3 text-muted small">Please note that cheque / RTGS / NEFT payments are subject to clearance</div>
         <% if current_client.disclaimer.present? %>
          <div class="mt-3 text-muted small">
            <strong>Disclaimer:</strong><br/>
            <%= current_client.disclaimer %>
          </div>
         <% end %>
       </div>
     </div>
     <% if current_client.enable_slot_generation? %>
       <div class="card mt-3">
         <div class="card-body">
           <h5 class="text-center"><strong>Token Details</strong></h5>
           <table class="table table-striped table-sm mt-3">
             <tbody>
               <tr>
                 <td>Token Number</td>
                 <td class="text-right"><%= self.try(:token_number) ? self.get_token_number : "--" %></td>
               </tr>
               <% if self.try(:time_slot) %>
                 <tr>
                   <td>Time Slot Date</td>
                   <td class="text-right"><%= self.time_slot.date.in_time_zone(self.user.time_zone).strftime("%d/%m/%Y") %></td>
                 </tr>
                 <tr>
                   <td>Start Time</td>
                   <td class="text-right"><%= self.time_slot.start_time.in_time_zone(self.user.time_zone).strftime("%I:%M %p") %></td>
                 </tr>
                 <tr>
                   <td>End Time</td>
                   <td class="text-right"><%= self.time_slot.end_time.in_time_zone(self.user.time_zone).strftime("%I:%M %p") %></td>
                 </tr>
                 <tr>
                   <td>Time Zone</td>
                   <td class="text-right"><%= self.user.time_zone %></td>
                 </tr>
               <% end %>
             </tbody>
           </table>
         </div>
       <% end %>
     </div>'
  end
end
