class Template::CostSheetTemplate < Template
  field :name, type: String
  field :default, type: Boolean, default: false

  validates :name, presence: true

  def self.default_content
    "
  <div class='form-sec-title pl-0'>Cost Sheet</div>
  <div class='box-card table-responsive-md template'>
    <table class='table '>
      <thead>
        <tr class='bg-gradient white'>
          <th>Item</th>
          <th>Details</th>
        </tr>
      </thead>
        <tbody>
          <% if self.project_unit.blocked_on.present? %>
            <tr>
              <td>Date of Issue</td><td class='text-nowrap'><%= self.project_unit.blocked_on %></td>
            </tr>
          <% end %>
          <tr>
              <td>Flat type</span></td>
          <td><%= self.project_unit.unit_configuration_name %></span></td>
          </tr>
          <tr>
            <td>Flat No.</span></td>
            <td><%= self.name %></span></td>
          </tr>
          <tr>
            <td>RERA Carpet Area (sq. mtr.)</span></td>
            <td><%= self.project_unit.carpet.round(2) %></span></td>
          </tr>
          <% self.calculated_data.each do |key, value| %>
            <tr>
              <td><%= key %></span></td>
              <td><%= value.round(2) %></span></td>
            </tr>
          <% end %>
          <% self.calculated_costs.each do |key, value| %>
            <tr>
              <td><%= key %></span></td>
              <td><%= value.round(2) %></span></td>
            </tr>
          <% end %>
        </tbody>
        <tfoot>
          <tr class='highlight'>
            <td>Agreement Value (Rs.)</td>
            <td><%= number_to_indian_currency(self.calculate_agreement_price) %></td>
          </tr>
          <tr class='highlight'>
            <td>All Inclusive Value (Rs.)</td>
            <td><%= number_to_indian_currency(self.calculate_all_inclusive_price) %></td>
          </tr>
          <tr>
          <td>Less: 6% of the Agreement Value as Input Tax Credit  (ITC)  against Goods & Service Tax (GST)</td>
          <td class='text-nowrap'><%= number_to_indian_currency((self.calculate_agreement_price * 0.06).round(2)) %></td>
        </tr>
        <tr>
          <td colspan='2' class='small'>The above payment schedule is valid for <%= project_unit.booking_portal_client.blocking_days %> days from the date of issue</td>
        </tr>
        <tr>
          <td colspan='2' class='small'>Stamp Duty, VAT/Service Tax/CGST/SGST/any other Govt. Tax extra as applicable and subject to change as per Government Rule. Input Tax Credit (ITC)against Goods & Service Tax(GST) is already adjusted and included in the final effective rates. </td>
        </tr>
        <tr>
          <td colspan='2' class='small'>Parking will be allotted/sold on request  </td>
        </tr>
        <tr>
          <td colspan='2' class='small'>All cheques/ Demand Draft should be drawn in the name of 'City Corporation Limited'(account of project as per RERA) </td>
        </tr>
        <tr>
          <td colspan='2' class='small'>Stamp duty/Registration/VAT/GST/Incidental charges/E-stamping charges/service tax: cheque/demand draft to be drawn in the name of 'City Corporation Limited' (account of project as per RERA) </td>
        </tr>
        <tr>
          <td colspan='2' class='small'>TDS @ 1 % on agreement value more than 50 lakh to be borne by customer against each payment made. Copy of receipt of payments to be submitted to CRM.   </td>
        </tr>
        </tfoot>
    </table>
  </div>
"
  end
end
