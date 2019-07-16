class Template::CostSheetTemplate < Template
  field :name, type: String
  field :default, type: Boolean, default: false

  validates :name, presence: true

  def self.default_content
    "
  <div class='form-sec-title pl-0'>Cost Sheet</div>
  <div class='box-card table-responsive-md'>
    <table class='table '>
      <thead>
          <tr class='bg-gradient white'>
              <th>Item</th>
          <th>Details</th>
        </tr>
      </thead>
        <tbody>
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
          <tr>
            <td>Agreement Value (Rs.)</td>
            <td><%= number_to_indian_currency(self.calculate_agreement_price) %></td>
          </tr>
          <tr>
            <td>All Inclusive Value (Rs.)</td>
            <td><%= number_to_indian_currency(self.calculate_all_inclusive_price) %></td>
          </tr>
        </tfoot>
    </table>
  </div>
"
  end
end
