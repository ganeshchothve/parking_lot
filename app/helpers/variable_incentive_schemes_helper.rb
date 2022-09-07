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

  def calculate_random_days variable_incentive_scheme
    random_days = (variable_incentive_scheme.end_date - Date.current).to_i
    random_days = random_days < 15 ? random_days : 15
    random_days = 0 if random_days <= 0
    @options.merge!({random_days: random_days})
    random_days
  end

  def total_earning_potential variable_incentive_scheme
    VariableIncentiveSchemeCalculator.maximum_incentive(query: [{id: variable_incentive_scheme.id}]).to_f * variable_incentive_scheme.total_bookings
  end
end