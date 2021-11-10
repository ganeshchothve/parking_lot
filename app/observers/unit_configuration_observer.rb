class UnitConfigurationObserver < Mongoid::Observer
  def before_save unit_configuration
    if unit_configuration.name_changed && unit_configuration.name.present?
      unit_configuration.project_units.update_all(unit_configuration_name: unit_configuration.name)
    end
  end
end
