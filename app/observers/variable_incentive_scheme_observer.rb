class VariableIncentiveSchemeObserver < Mongoid::Observer

  def before_validation(variable_incentive_scheme)
    _event = variable_incentive_scheme.event.to_s
    variable_incentive_scheme.event = nil
    if _event.present? && (variable_incentive_scheme.aasm.current_state.to_s != _event.to_s)
      if variable_incentive_scheme.send("may_#{_event.to_s}?")
        variable_incentive_scheme.aasm.fire!(_event.to_sym)
      else
        variable_incentive_scheme.errors.add(:status, 'transition is invalid')
      end
    end
  end

  def before_save(variable_incentive_scheme)
    variable_incentive_scheme.scheme_days = ((variable_incentive_scheme.end_date - variable_incentive_scheme.start_date).to_i + 1) if variable_incentive_scheme.draft?
  end

end