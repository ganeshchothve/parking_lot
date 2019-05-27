class Template::BookingDetailTemplate < Template
  field :name, type: String
  field :default, type: Boolean, default: false

  validates :name, presence: true

  def self.default_content
    "<h3 class='mb-3'>Cost Sheet</h3>
    <table class='table'>
      <thead>
        <tr>
          <th>Item</th><th class='text-right'>Details</th>
        </tr>
      </thead>
      <tbody>
        <% if self.project_unit.blocked_on.present? %>
        <tr>
          <td>Date of Issue</td><td class='text-right'><%= self.project_unit.blocked_on %></td>
        </tr>
        <% end %>
        <tr>
          <td>Flat type</td><td class='text-right'><%= self.project_unit.unit_configuration_name %></td>
        </tr>
        <tr>
          <td>Flat No.</td><td class='text-right'><%= self.name %></td>
        </tr>
        <tr>
          <td>RERA Carpet Area (sq. mtr.)</td><td class='text-right'><%= self.project_unit.carpet.round(2) %></td>
        </tr>
        <% self.calculated_data.each do |key, value| %>
          <tr>
            <td><%= key %></td>
            <td class='text-right'><%= value.round(2) %></td>
          </tr>
        <% end %>
        <tr>
          <td>Premium inclusive of proportionate price for common amenities & facilities.(i)</td><td class='text-right'><%= number_to_indian_currency(self.project_unit.base_price.round(2)) %></td>
        </tr>
        <% self.calculated_costs.each do |key, value| %>
          <tr>
            <td><%= key %></td>
            <td class='text-right'><%= value.round(2) %></td>
          </tr>
        <% end %>
        <tr class='text-white bg-primary'>
          <td>Agreement Value (Rs.)</td>
          <td class='text-right'><%= number_to_indian_currency(self.calculate_agreement_price) %></td>
        </tr>
        <tr class='text-white bg-primary'>
          <td>All inclusive Value (Rs.)</td>
          <td class='text-right'><%= number_to_indian_currency(self.calculate_all_inclusive_price) %></td>
        </tr>
        <tr>
          <td>Less: 6% of the Agreement Value as Input Tax Credit  (ITC)  against Goods & Service Tax (GST)</td>
          <td class='text-right'><%= number_to_indian_currency((self.calculate_agreement_price * 0.06).round(2)) %></td>
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
      </tbody>
    </table>"
  end
end
