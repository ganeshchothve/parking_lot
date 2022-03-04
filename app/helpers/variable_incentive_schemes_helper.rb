module VariableIncentiveSchemesHelper
  def custom_variable_incentive_schemes_path
    admin_variable_incentive_schemes_path
  end

  def available_statuses variable_incentive_scheme
    if variable_incentive_scheme.new_record?
      [ 'draft' ]
    else
      statuses = variable_incentive_scheme.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end

  def filter_project_names_options
    Project.pluck(:name,:id)
  end
end