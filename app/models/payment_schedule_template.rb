# GENERICTODO: To be replaced with Email Template at a later stage
class PaymentScheduleTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  def self.default_content
    '<table class="table">
      <thead>
        <td width="60%">Milestone</td>
        <td width="5%">%</td>
        <td width="10%">Amount(Rs.)</td>
        <td width="5%">CGST-6%</td>
        <td width="5%">SGST-6%</td>
        <td width="5%">Less - TDS</td>
        <td width="10%">Total Payable on milestone</td>
      </thead>
      <tbody>
        <%
          hash = {
            "Booking": 10,
            "Upon execution of Agreement": 5,
            "Completion of the Plinth": 10,
            "Completion of 1st Slab": 5,
            "Completion of 4th Slab": 5,
            "Completion of 8th Slab": 5,
            "Completion of 12th Slab": 5,
            "Completion of 16th Slab": 5,
            "Completion of 20th Slab": 5,
            "Completion of 24th Slab": 5,
            "Completion of 28th Slab": 5,
            "Completion of 33rd Slab": 5,
            "Completion of  walls, internal plaster, floorings doors & windows": 5,
            "Completion of sanitary fittings, staircases, lift wells, lobbies upto the floor level of the said unit.": 5,
            "Completion of the external plumbing and external plaster, elevation, terraces with waterproofing, of the building or wing in which the said unit is located": 5,
            "Completion of  the lifts, water pumps, electrical fittings, electro, mechanical and environmental requirements of the building in which the said unit is located":  5,
            "Completion of  the entrance lobby/s, plinth protection, paving of area appertain and all other requirements  of the building in which the said unit is located":  5,
            "At the time of Taking Possession of the said unit on or after receipt of occupancy certificate from the concerned government authority.": 5
          }
        %>
        <% hash.each do |k, v| %>
          <%
            current_value = (self.agreement_price * v / 100).round()
            cgst = (current_value * 0.06).round()
            sgst = (current_value * 0.06).round()
            tds = (current_value * 0.01).round()
          %>
          <tr>
            <td><%= k %></td>
            <td><%= v %></td>
            <td><%= current_value %></td>
            <td><%= cgst %></td>
            <td><%= sgst %></td>
            <td><%= tds %></td>
            <td><%= current_value + cgst + sgst - tds %></td>
          </tr>
        <% end %>
      </tbody>
    </table>'
  end

  field :content, type: String, default: PaymentScheduleTemplate.default_content

  belongs_to :booking_portal_client, class_name: "Client"

  validates :content, presence: true

  def parsed_content project_unit
    unless project_unit.is_a?(ProjectUnit)
      return nil
    end
    return ERB.new(self.content).result( project_unit.get_binding ).html_safe
  end
end
