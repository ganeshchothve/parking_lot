class VariableIncentiveSchemeCalculator

  def self.channel_partner_incentive(options={})
    approved_schemes = VariableIncentiveScheme.approved
    incentive_data = []
    incentive_amount = 0
    query = get_query(options)
    approved_schemes.each_with_index do |variable_incentive_scheme, index|

      booking_details = BookingDetail.in(status: BookingDetail::BOOKING_STAGES, project_id: variable_incentive_scheme.project_ids).where(booked_on: variable_incentive_scheme.start_date.beginning_of_day..variable_incentive_scheme.end_date.end_of_day).where(query)

      booking_details.each_with_index do |booking_detail, index|
        incentive_amount += calculate_capped_incentive(booking_detail, variable_incentive_scheme, booking_details.count)
      end

      if query[:manager_id].present?
        user = User.where(_id: query[:manager_id]).first
        user_hash = {user_id: user.try(:id).to_s, user_name: user.name}
      else
        user_hash = {user_id: nil, user_name: I18n.t("global.all") }
      end
      incentive_data << {variable_incentive_scheme_id: variable_incentive_scheme.id.to_s, variable_incentive_scheme_name: variable_incentive_scheme.name, total_capped_incentive: incentive_amount}.merge(user_hash)
      incentive_amount = 0
    end
    incentive_data
  end

  def self.vis_details(options={})
    incentive_data = []
    options = options.with_indifferent_access
    filter_query = options[:query]
    variable_incentive_schemes = VariableIncentiveScheme.approved.or(filter_query)
    query = get_query(options)
    if variable_incentive_schemes.present?
      variable_incentive_schemes.each do |variable_incentive_scheme|
        booking_details = BookingDetail.in(status: BookingDetail::BOOKING_STAGES, project_id: variable_incentive_scheme.project_ids).where(booked_on: variable_incentive_scheme.start_date.beginning_of_day..variable_incentive_scheme.end_date.end_of_day).where(query)
        booking_count = booking_details.count

        booking_details.includes(:project, :manager).each do |booking_detail|
          day = VariableIncentiveSchemeCalculator.calculate_days(booking_detail, variable_incentive_scheme)
          capped_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(booking_detail, variable_incentive_scheme, booking_count)
          incentive_data << {scheme_name: variable_incentive_scheme.name, scheme_id: variable_incentive_scheme.id.to_s, total_bookings: variable_incentive_scheme.total_bookings, day: day, project_name: booking_detail.project.try(:name), project_id: booking_detail.project_id.to_s, booking_detail_id: booking_detail.id.to_s, booking_detail_name: booking_detail.name, capped_incentive: capped_incentive, manager_name: booking_detail.manager_name, manager_id: booking_detail.manager_id.to_s, company_name: booking_detail.manager.try(:channel_partner).try(:company_name), first_name: booking_detail.manager.try(:first_name), last_name: booking_detail.manager.try(:last_name)}
        end
      end
    end
    incentive_data.sort_by!{|data| data[:day] }
  end

  def self.average_incentive_per_booking_prediction(options={})
    filter_query = options[:query]
    average_incentive = 0
    predicted_incentive = 0
    variable_incentive_scheme = VariableIncentiveScheme.approved.or(filter_query).first
    if variable_incentive_scheme.present?
      start_date = Date.today - 5
      end_date = Date.today
      # last 5 days booking count
      booking_count = BookingDetail.in(status: BookingDetail::BOOKING_STAGES, project_id: variable_incentive_scheme.project_ids).where(booked_on: start_date.beginning_of_day..end_date.end_of_day).count
      # avg booking count per day
      booking_count = (booking_count <= 1 ? 1 : booking_count)
      avg_booking_count_per_day = (booking_count.to_f / 5).ceil
      avg_booking_count_per_day = (avg_booking_count_per_day <= 1 ? 1 : avg_booking_count_per_day)
      predicted_booking_count = avg_booking_count_per_day * 7
      (0..7).each do |day|
        booking_detail = BookingDetail.new(booked_on: Date.today + day)
        capped_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(booking_detail, variable_incentive_scheme, booking_count)
        predicted_incentive += (capped_incentive * avg_booking_count_per_day)
      end

      average_incentive = (predicted_incentive.to_f / 7).round
    end
    average_incentive
  end

  def self.maximum_incentive(options={})
    filter_query = options[:query]
    variable_incentive_scheme = VariableIncentiveScheme.approved.or(filter_query).first
    max_capped_incentive = 0
    if variable_incentive_scheme.present?
      booking_detail = BookingDetail.new(booked_on: variable_incentive_scheme.start_date)
      max_capped_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(booking_detail, variable_incentive_scheme)
    end
    max_capped_incentive
  end

  def self.total_maximum_capped_incentive(options={})
    filter_query = options[:query]
    variable_incentive_scheme = VariableIncentiveScheme.approved.or(filter_query).first
    total_maximum_capped_incentive = 0
    if variable_incentive_scheme.present?
      total_maximum_capped_incentive = maximum_incentive(options) * variable_incentive_scheme.total_bookings
    end
    total_maximum_capped_incentive
  end

  # this method not used yet
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
  def self.calculate_network_factor(variable_incentive_scheme, booking_count=nil)
    network_factor = (booking_count || variable_incentive_scheme.total_bookings).to_f / variable_incentive_scheme.total_inventory.to_f
    network_factor
  end

  # days_effect * network_factor
  def self.calculate_days_incentive(booking_detail, variable_incentive_scheme, booking_count=nil)
    days_effect = calculate_days_effect(booking_detail, variable_incentive_scheme)
    network_factor = calculate_network_factor(variable_incentive_scheme, booking_count)
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
  def self.calculate_network_effect(variable_incentive_scheme, booking_count=nil)
    network_effect = (booking_count || variable_incentive_scheme.total_bookings) * variable_incentive_scheme.total_bookings_multiplier
    network_effect
  end

  # days_factor * network_effect
  def self.calculate_network_incentive(booking_detail, variable_incentive_scheme, booking_count=nil)
    days_factor = calculate_days_factor(booking_detail, variable_incentive_scheme)
    network_effect = calculate_network_effect(variable_incentive_scheme, booking_count)
    network_incentive = days_factor * network_effect
    network_incentive
  end

  # Days Incentive + Network Incentive + Min Incentive
  def self.calculate_total_incentive(booking_detail, variable_incentive_scheme, booking_count=nil)
    days_incentive = calculate_days_incentive(booking_detail, variable_incentive_scheme, booking_count)
    network_incentive = calculate_network_incentive(booking_detail ,variable_incentive_scheme, booking_count)
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
  def self.calculate_capped_incentive(booking_detail, variable_incentive_scheme, booking_count=nil)
    total_incentive = calculate_total_incentive(booking_detail, variable_incentive_scheme, booking_count)
    temp_capped_incentive = calculate_temp_capped_incentive(variable_incentive_scheme)
    capped_incentive = [total_incentive, temp_capped_incentive].min
    capped_incentive.round
  end

  def self.get_query(options = {})
    query = {}
    if options.present?
      query.merge!({manager_id: options[:user_id]}) if options[:user_id].present?
      query.merge!({project_id: {"$in": options[:project_ids]}}) if options[:project_ids].present?
    end
    query
  end

end
