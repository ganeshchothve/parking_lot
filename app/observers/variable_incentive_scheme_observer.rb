class VariableIncentiveSchemeObserver < Mongoid::Observer
  def before_create(variable_incentive_scheme)
    variable_incentive_scheme.scheme_days = ((variable_incentive_scheme.end_date - variable_incentive_scheme.start_date).to_i + 1)
  end
end