# GENERICTODO: To be replaced with Email Template at a later stage
class CostSheetTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  def self.default_content
    "<table class='table'>"+
    "<thead><tr><th>Item</th><th>Details</th></tr></thead>" +
    "<tbody>" +
    "<tr><td>Date of Issue</td><td>{{blocked_on}}</td></tr>" +
    "<tr><td>Flat type</td><td>{{unit_configuration_name}}</td></tr>" +
    "<tr><td>RERA Carpet Area ({{booking_portal_client.area_unit}})</td><td>{{carpet}}</td></tr>" +
    "<tr><td>Balcony Area ({{booking_portal_client.area_unit}})</td><td>{{calculated_data.Balcony}}</td></tr>" +
    "<tr><td>Enclosed Balcony Area ({{booking_portal_client.area_unit}})</td><td>{{calculated_data.Balcony}}</td></tr>" +
    "<tr><td>Parking</td><td>{{calculated_costs.Parking}}</td></tr>" +
    "<tr><td>Agreement Value</td><td>{{agreement_price}}</td></tr>" +
    "</tbody>" +
    "</table>"
  end

  field :content, type: String, default: CostSheetTemplate.default_content

  belongs_to :booking_portal_client, class_name: "Client"

  validates :content, presence: true

  def parsed_content project_unit
    unless project_unit.is_a?(ProjectUnit)
      return nil
    end
    return TemplateParser.parse(self.content, project_unit)
  end
end
