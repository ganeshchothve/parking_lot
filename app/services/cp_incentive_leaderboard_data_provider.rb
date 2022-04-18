module CpIncentiveLeaderboardDataProvider
  # Top 10 Channel partner name - Total CP payout
  def self.top_channel_partners(options = {})
    vis_data = VariableIncentiveSchemeCalculator.vis_details(options)
    manager_wise_total_incentive_data = []

    if vis_data.present?
      data_group_by_manager = vis_data.group_by{|data| data[:manager_id] }
      data_group_by_manager.each do |key, value|
        hash = {}
        hash[:manager_id] = key
        hash[:manager_name] = value.pluck(:manager_name).first.to_s
        hash[:total_capped_incentive] = value.pluck(:capped_incentive).sum
        manager_wise_total_incentive_data << hash
      end
      incentives = manager_wise_total_incentive_data.pluck(:total_capped_incentive)
      ranks = calculate_ranks(incentives)
      manager_wise_total_incentive_data.each_with_index do |data, index|
        data.merge!(rank: ranks[index])
      end
    end

    manager_wise_total_incentive_data.sort_by!{|d| d[:rank] }
  end

  # Highest incentive per booking - CP Name
  def self.highest_incentive_per_booking(options = {})
    vis_data = VariableIncentiveSchemeCalculator.vis_details(options)
    highest_incentive_per_booking_data = []
    if vis_data.present?
      max_incentive = vis_data.pluck(:capped_incentive).max
      highest_incentive_per_booking_data = vis_data.select{|d| d[:capped_incentive] == max_incentive }
    end
    highest_incentive_per_booking_data
  end

  # Average incentive per booking - All bookings
  def self.average_incentive_per_booking(options = {})
    vis_data = VariableIncentiveSchemeCalculator.vis_details(options)
    average_incentive = 0
    if vis_data.present?
      incentives = vis_data.pluck(:capped_incentive).sum
      bookings_count = vis_data.count
      average_incentive = (incentives.to_f / bookings_count).round(2)
    end
    average_incentive
  end

  # Current(today's) incentive per booking
  def self.incentive_predictions(options = {})
    incentive_predictions = []
    yesterday_booking_detail = BookingDetail.new(booked_on: Date.today - 1)
    todays_booking_detail = BookingDetail.new(booked_on: Date.today)
    tomorrow_booking_detail = BookingDetail.new(booked_on: Date.today + 1)
    next_week_booking_detail = BookingDetail.new(booked_on: Date.today + 7)
    # TODO: Need to give project id filter for approved_schemes
    approved_schemes = VariableIncentiveScheme.approved.or(options[:query])
    if approved_schemes.present?
      approved_schemes.each do |variable_incentive_scheme|
        booking_details = BookingDetail.in(status: BookingDetail::BOOKING_STAGES, project_id: variable_incentive_scheme.project_ids).where(booked_on: variable_incentive_scheme.start_date.beginning_of_day..variable_incentive_scheme.end_date.end_of_day)
        booking_count = booking_details.count

        yesterday_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(yesterday_booking_detail, variable_incentive_scheme, booking_count)
        today_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(todays_booking_detail, variable_incentive_scheme, booking_count)
        tomorrow_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(tomorrow_booking_detail, variable_incentive_scheme, booking_count)
        next_week_incentive = VariableIncentiveSchemeCalculator.calculate_capped_incentive(next_week_booking_detail, variable_incentive_scheme, booking_count)

        incentive_predictions << {variable_incentive_scheme_id: variable_incentive_scheme.id.to_s, project_ids: variable_incentive_scheme.project_ids, yesterday_incentive: yesterday_incentive, today_incentive: today_incentive, tomorrow_incentive: tomorrow_incentive, next_week_incentive: next_week_incentive}
      end
    end
    incentive_predictions
  end

  # Target Vs Achieved count
  def self.achieved_target(options = {})
    vis_data = VariableIncentiveSchemeCalculator.vis_details(options)
    achieved_target_data = []
    if vis_data.present?
     group_by_scheme = vis_data.group_by{|d| d[:scheme_name] }
     group_by_scheme.each do |key, value|
       achieved_target_data << {scheme_name: key, target: value.first[:total_bookings], achieved_target: value.count}
     end
    end
    achieved_target_data
  end


  def self.calculate_ranks(arr)
    sorted = arr.sort.uniq.reverse
    ranks = arr.map{|e| sorted.index(e) + 1}
    ranks
  end
end
