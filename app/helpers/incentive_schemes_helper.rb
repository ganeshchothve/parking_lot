module IncentiveSchemesHelper
  def custom_incentive_schemes_path
    admin_incentive_schemes_path
  end

  def available_statuses incentive_scheme
    if incentive_scheme.new_record?
      [ 'draft' ]
    else
      statuses = incentive_scheme.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end

end
