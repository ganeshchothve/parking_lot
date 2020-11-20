class IncentiveSchemeObserver < Mongoid::Observer
  def before_validation(incentive_scheme)
    _event = incentive_scheme.event.to_s
    incentive_scheme.event = nil
    if _event.present? && (incentive_scheme.aasm.current_state.to_s != _event.to_s)
      if incentive_scheme.send("may_#{_event.to_s}?")
        incentive_scheme.aasm.fire!(_event.to_sym)
      else
        incentive_scheme.errors.add(:status, 'transition is invalid')
      end
    end
  end
end
