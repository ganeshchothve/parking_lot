class ProjectUnitObserver < Mongoid::Observer
  def before_validation project_unit
    update_prices(project_unit)
  end

  def before_save project_unit
    if project_unit.status == 'available'
      project_unit.floor_rise = project_unit.new_floor_rise if project_unit.new_floor_rise.present? && (project_unit.status_changed? || project_unit.new_floor_rise_changed?)
      project_unit.base_rate = project_unit.new_base_rate if project_unit.new_base_rate.present? && (project_unit.status_changed? || project_unit.new_base_rate_changed?)
      project_unit.blocking_amount = project_unit.new_blocking_amount if project_unit.new_blocking_amount.present? && (project_unit.status_changed? || project_unit.new_blocking_amount_changed?)
      project_unit.costs.where(new_absolute_value: {"$ne": nil}, formula: {'$in': ['', nil]}).each do |cost|
        cost.assign_attributes(absolute_value: cost.new_absolute_value) if cost.new_absolute_value.present? && (project_unit.status_changed? || cost.new_absolute_value_changed?)
      end
      project_unit.costs.where(new_formula: {"$ne": nil}).each do |cost|
        cost.assign_attributes(formula: cost.new_formula, absolute_value: nil) if cost.new_formula.present? && (project_unit.status_changed? || cost.new_formula_changed?)
      end
      project_unit.data.where(new_absolute_value: {"$ne": nil}, formula: {'$in': ['', nil]}).each do |_data|
        _data.assign_attributes(absolute_value: _data.new_absolute_value) if _data.new_absolute_value.present? && (project_unit.status_changed? || _data.new_absolute_value_changed?)
      end
    end
    update_prices(project_unit)
  end

  def update_prices project_unit
    project_unit.agreement_price = project_unit.calculate_agreement_price.round
    project_unit.all_inclusive_price = project_unit.calculate_all_inclusive_price.round
  end
end
