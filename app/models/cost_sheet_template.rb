# GENERICTODO: To be replaced with Email Template at a later stage
class CostSheetTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  def self.default_content
    "<table class='table'>"+
    "<thead><tr><th>Item</th><th class='text-right'>Details</th></tr></thead>" +
    "<tbody>" +
    "<tr><td>Date of Issue</td><td class='text-right'><%= blocked_on %></td></tr>" +
    "<tr><td>Flat type</td><td class='text-right'><%= unit_configuration_name %></td></tr>" +
    "<tr><td>RERA Carpet Area (<%= booking_portal_client.area_unit %>)</td><td class='text-right'><%= carpet %></td></tr>" +
    "<tr><td>Balcony Area (<%= booking_portal_client.area_unit %>)</td><td class='text-right'><%= calculated_data['balcony'] %></td></tr>" +
    "<tr><td>Enclosed Balcony Area (<%= booking_portal_client.area_unit %>)</td><td class='text-right'><%= calculated_data['covered_balcony'] %></td></tr>" +
    "<tr><td>Parking</td><td class='text-right'><%= calculated_costs['parking'] %></td></tr>" +
    "<tr><td>Agreement Value</td><td class='text-right'><%= number_to_indian_currency(agreement_price) %></td></tr>" +
    "</tbody>" +
    "</table>"
  end

  field :content, type: String, default: CostSheetTemplate.default_content

  belongs_to :booking_portal_client, class_name: "Client"

  validates :content, presence: true

  def parsed_content project_unit
    unless project_unit.is_a?(ProjectUnit)
      return ""
    end
    return ERB.new(content).result( project_unit.get_binding ).html_safe
  end
end
