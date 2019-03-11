module ProjectUnitHelper

  def floor_plan_asset(project_unit)
    project_unit.assets.where(asset_type: 'floor_plan').first || project_unit.assets.build(asset_type: :floor_plan)
  end
end