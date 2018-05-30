class UpgradePricing
  def self.perform
    ['Daisy', 'Gardenia', 'Hibisicus', 'Fuchsia', 'Elderberry'].each do |project_tower_name|
      project_tower_ids = ProjectTower.where(name: Regexp.new(project_tower_name, "ig")).distinct(:id)
      updated_rate = get_upgraded_base_rate(project_tower_name, project_tower_ids)
      current_max_rate = ProjectUnit.in(project_tower_id: project_tower_ids).max(:base_rate)
      if updated_rate > current_max_rate
        ProjectUnit.where(status: "available").in(project_tower_id: project_tower_ids).each do |project_unit|
          project_unit.base_rate = updated_rate
          project_unit.calculate_agreement_price
          if project_unit.save
            ApplicationLog.log("price_upgraded", {
              updated_rate: updated_rate,
              current_max_rate: current_max_rate,
              project_unit_id: project_unit.id.to_s
            })
          else
            ApplicationLog.log("error_in_price_upgrad", {
              updated_rate: updated_rate,
              current_max_rate: current_max_rate,
              project_unit_id: project_unit.id.to_s
            })
          end
        end
      end
    end
  end

  def self.get_upgraded_base_rate project_tower_name, project_tower_ids=[]
    project_tower_ids = ProjectTower.where(name: Regexp.new(project_tower_name, "ig")).distinct(:id) if project_tower_ids.blank?
    sold_count = ProjectUnit.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).in(project_tower_id: project_tower_ids.to_a).count
    total_count = ProjectUnit.in(project_tower_id: project_tower_ids.to_a).count
    rates = {
      'Daisy': {new: 4600, old: 4475},
      'Gardenia': {new: 4500, old: 4375},
      'Hibisicus': {new: 4550, old: 4425},
      'Fuchsia': {new: 4700, old: 4575},
      'Elderberry': {new: 4675, old: 4550}
    }.with_indifferent_access
    if sold_count >= (total_count / 2).to_i
      return rates[project_tower_name]['new']
    else
      return rates[project_tower_name]['old']
    end
  end
end
