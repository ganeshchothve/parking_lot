module ProjectUnitHelper

  def floor_plan_asset(project_unit)
    project_unit.assets.where(asset_type: 'floor_plan').first || project_unit.assets.build(asset_type: :floor_plan)
  end

  def unit_tooltip(unit)
    html_content = "<div class='row mb-3' style='width:350px;'>
                  <div class='col-md-4'><label>Beds</label><div>#{unit.bedrooms}</div></div>
                  <div class='col-md-4'><label>Apartment</label><div>#{unit.floor_order}</div></div>
                  <div class='col-md-4'><label>Carpet</label><div>#{unit.carpet} #{current_client.area_unit}</div></div>
                  <div class='col-md-4'><label>Facing</label><div>#{unit.unit_facing_direction}</div></div>
                "
    unless unit.status == 'blocked'
      html_content += "<div class='col-md-4'><label>Agreement Value</label><div>#{number_to_indian_currency(unit.agreement_price)}</div></div>
      <div class='col-md-4'><label>All Inclusive Price</label><div>#{number_to_indian_currency(unit.all_inclusive_price)}</div></div>"
    end
    html_content += "</div>"
    html_content
  end

  def comment(unit)
  if unit.comments.present?
    html_content = "<div class='row mb-3' style='width:350px;'>
                    <div class='col-md-4'><p>#{unit.comments}</p></div>
                  </div>"
  end
  html_content
  end
end
