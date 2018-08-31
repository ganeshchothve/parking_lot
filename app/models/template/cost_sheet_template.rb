class Template::CostSheetTemplate < Template
  def self.default_content
    "<h3 class='mb-3'>Cost Sheet</h3>
    <table class='table'>
      <thead>
        <tr>
          <th>Item</th><th class='text-right'>Details</th>
        </tr>
      </thead>
      <tbody>
        <% if blocked_on.present? %>
        <tr>
          <td>Date of Issue</td><td class='text-right'><%= blocked_on %></td>
        </tr>
        <% end %>
        <tr>
          <td>Flat type</td><td class='text-right'><%= unit_configuration_name %></td>
        </tr>
        <tr>
          <td>Flat No.</td><td class='text-right'><%= name %></td>
        </tr>
        <tr>
          <td>RERA Carpet Area (sq. mtr.)</td><td class='text-right'><%= carpet.round(2) %></td>
        </tr>
        <tr>
          <td>Balcony Area (sq. mtr.)</td><td class='text-right'><%= calculated_data['total_balcony_area'].round(2) %></td>
        </tr>
        <tr>
          <td>Enclosed Balcony Area (sq. mtr.)</td><td class='text-right'><%= calculated_data['enclosed_balcony'].round(2) %></td>
        </tr>
        <tr>
          <td>Premium inclusive of proportionate price for common amenities & facilities.(i)</td><td class='text-right'><%= number_to_indian_currency(base_price.round(2)) %></td>
        </tr>
        <tr>
          <td>Covered Car Parking premium (Rs.) (ii)</td>
          <td class='text-right'><%= number_to_indian_currency(calculated_costs['car_parking'].round(2)) %></td>
        </tr>
        <tr class='text-white bg-primary'>
          <td>Agreement Value (Rs.) (i) +(ii)---{A}</td><td class='text-right'><%= number_to_indian_currency(agreement_price) %></td>
        </tr>
        <tr class='text-white bg-secondary'>
          <td colspan='2'>Legal charges</td>
        </tr>
        <tr>
          <td>Stamp duty</td>
          <td class='text-right'><%= number_to_indian_currency(calculated_costs['stamp_duty_charges'].round(2)) %></td>
        </tr>
        <tr>
          <td>Registration</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['reg_charges'].round(2)) %></td>
        </tr>
        <tr>
          <td>Incidental charges</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['incidental_charges'].round(2)) %></td>
        </tr>
        <tr>
          <td>E-Stamping charges</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['estamping_charges'].round(2)) %></td>
        </tr>
        <tr>
          <td>VAT / Goods & Service Tax </td>
          <td class='text-right'><%= number_to_indian_currency(calculated_costs['vat_gst'].round(2)) %></td>
        </tr>
        <tr class='text-white bg-primary'>
          <%
            legal_total = calculated_costs['stamp_duty_charges'] + calculated_costs['reg_charges'] + calculated_costs['incidental_charges'] + calculated_costs['vat_gst'] + calculated_costs['estamping_charges'] rescue 0
            legal_total = legal_total.round(2)
          %>
          <td>Sub total - legal charges ---{B}</td><td class='text-right'><%= number_to_indian_currency(legal_total) %></td>
        </tr>
        <tr class='text-white bg-secondary'>
          <td colspan='2'>At the time of possession</td>
        </tr>
        <tr>
          <td>Utility Charges - Power/Gas/Water</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['utility_charges'].round(2)) %></td>
        </tr>
        <tr>
          <td>Amanora Cluster Fund</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['amanora_cluster_fund'].round(2)) %></td>
        </tr>
        <tr>
          <td>Infrastructure Charges (Yearly)</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['infra_charges'].round(2)) %></td>
        </tr>
        <tr>
          <td>Amanora Environment Fund (Yearly)</td><td class='text-right'><%= number_to_indian_currency(calculated_costs['env_fund'].round(2)) %></td>
        </tr>
        <tr class='text-white bg-primary'>
          <%
            sub_total = calculated_costs['utility_charges'] + calculated_costs['amanora_cluster_fund'] + calculated_costs['env_fund'] + calculated_costs['infra_charges']  rescue 0
            sub_total = sub_total.round(2)
          %>
          <td>SUBTOTAL - ON POSSESSION ---{C}</td>
          <td class='text-right'><%= number_to_indian_currency(sub_total) %></td>
        </tr>
        <tr class='text-white bg-primary'>
          <td>TOTAL COST OF THE UNIT - {A+B+C} </td>
          <td class='text-right'><%= number_to_indian_currency((sub_total + legal_total + agreement_price).round(2)) %></td>
        </tr>
        <tr>
          <td>Less: 6% of the Agreement Value as Input Tax Credit  (ITC)  against Goods & Service Tax (GST)</td>
          <td class='text-right'><%= number_to_indian_currency((agreement_price * 0.06).round(2)) %></td>
        </tr>
        <tr class='text-white bg-primary'>
          <td>FINAL COST OF THE UNIT </td>
          <td class='text-right'><%= number_to_indian_currency((sub_total + legal_total + agreement_price - (agreement_price * 0.06)).round(2)) %></td>
        </tr>
        <tr>
          <td colspan='2' class='small'>The above payment schedule is valid for <%= booking_portal_client.blocking_days %> days from the date of issue</td>
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
