class VariableIncentiveSchemeCalculator

  def self.channel_partner_incentive(user, options={})
    approved_schemes = VariableIncentiveScheme.approved
    incentive_data = []
    incentive_amount = 0

    approved_schemes.each_with_index do |variable_incentive_scheme, index|

      booking_details = BookingDetail.where(manager_id: user.id).in(status: BookingDetail::BOOKING_STAGES, project_id: variable_incentive_scheme.project_ids).where(booked_on: variable_incentive_scheme.start_date.beginning_of_day..variable_incentive_scheme.end_date.end_of_day)

      booking_details.each_with_index do |booking_detail, index|
        incentive_amount += calculate_capped_incentive(booking_detail, variable_incentive_scheme)
      end

      incentive_data << {user_id: user.id.to_s, user_name: user.name, variable_incentive_scheme_id: variable_incentive_scheme.id.to_s, variable_incentive_scheme_name: variable_incentive_scheme.name, total_capped_incentive: incentive_amount}
      incentive_amount = 0
    end
    incentive_data
  end

  def self.all_channel_partners_incentives(options={})
    # need to discuss this user roles
    # how many cps need to show at a time
    cps = User.channel_partner
    incentives_data = {}
    cps.each do |cp|
      cp_id = cp.id.to_s
      incentives_data[cp_id] = channel_partner_incentive(cp, options={})
    end
    incentives_data
  end

  # (scheme_days - calculate_days) * days_multiplier
  def self.calculate_days_effect(booking_detail, variable_incentive_scheme)
    calculated_days = calculate_days(booking_detail, variable_incentive_scheme)
    days_effect = (variable_incentive_scheme.scheme_days - calculated_days) * variable_incentive_scheme.days_multiplier
    days_effect
  end

  # (booking booked_on - scheme start date) + 1
  def self.calculate_days(booking_detail, variable_incentive_scheme)
    days_difference = (booking_detail.booked_on - variable_incentive_scheme.start_date).to_i + 1
    days = [days_difference, 0].max
    days
  end

  # total_bookings / total_inventory
  def self.calculate_network_factor(variable_incentive_scheme)
    network_factor = variable_incentive_scheme.total_bookings.to_f / variable_incentive_scheme.total_inventory.to_f
    network_factor
  end

  # days_effect * network_factor
  def self.calculate_days_incentive(booking_detail, variable_incentive_scheme)
    days_effect = calculate_days_effect(booking_detail, variable_incentive_scheme)
    network_factor = calculate_network_factor(variable_incentive_scheme)
    days_incentive = days_effect * network_factor
    days_incentive
  end

  # (scheme_days - calculated_days) / scheme_days
  def self.calculate_days_factor(booking_detail, variable_incentive_scheme)
    difference = (variable_incentive_scheme.scheme_days - calculate_days(booking_detail, variable_incentive_scheme))
    difference = [difference, 0].max
    days_factor = difference.to_f / variable_incentive_scheme.scheme_days
    days_factor
  end

  # (total_bookings * total_bookings_multiplier)
  def self.calculate_network_effect(variable_incentive_scheme)
    network_effect = variable_incentive_scheme.total_bookings * variable_incentive_scheme.total_bookings_multiplier
    network_effect
  end

  # days_factor * network_effect
  def self.calculate_network_incentive(booking_detail, variable_incentive_scheme)
    days_factor = calculate_days_factor(booking_detail, variable_incentive_scheme)
    network_effect = calculate_network_effect(variable_incentive_scheme)
    network_incentive = days_factor * network_effect
    network_incentive
  end

  # Days Incentive + Network Incentive + Min Incentive
  def self.calculate_total_incentive(booking_detail, variable_incentive_scheme)
    days_incentive = calculate_days_incentive(booking_detail, variable_incentive_scheme)
    network_incentive = calculate_network_incentive(booking_detail ,variable_incentive_scheme)
    min_incentive = variable_incentive_scheme.min_incentive
    total_incentive = days_incentive + network_incentive + min_incentive
    total_incentive
  end

  # average_revenue_or_bookings * max_expense_percentage
  def self.calculate_temp_capped_incentive(variable_incentive_scheme)
    temp_capped_incentive = variable_incentive_scheme.average_revenue_or_bookings * variable_incentive_scheme.max_expense_percentage
    temp_capped_incentive
  end

  # [total_incentive, temp_capped_incentive].min
  def self.calculate_capped_incentive(booking_detail, variable_incentive_scheme)
    total_incentive = calculate_total_incentive(booking_detail, variable_incentive_scheme)
    temp_capped_incentive = calculate_temp_capped_incentive(variable_incentive_scheme)
    capped_incentive = [total_incentive, temp_capped_incentive].min
    capped_incentive.round
  end

end