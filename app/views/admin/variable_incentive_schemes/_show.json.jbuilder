projects = Project.where(booking_portal_client_id: variable_incentive_scheme.booking_portal_client_id).in(id: variable_incentive_scheme.project_ids).to_a
random_days = calculate_random_days(variable_incentive_scheme)
incentive_predictions_data = CpIncentiveLeaderboardDataProvider.incentive_predictions(@options)

json.(variable_incentive_scheme, :id, :name, :start_date, :end_date, :total_bookings)

json.total_earning_potential total_earning_potential(variable_incentive_scheme)
json.todays_incentive (incentive_predictions_data.first[:today_incentive] rescue 0.0)
json.random_days random_days
json.random_days_incentive (incentive_predictions_data.first[:random_days] rescue 0.0)
json.avg_booking_count_incentive VariableIncentiveSchemeCalculator.maximum_incentive(query: [{id: variable_incentive_scheme.id}]).to_f

json.project_urls (projects.collect { |pr| pr.try(:mobile_logo_url)}).compact
json.message I18n.t('mongoid.attributes.variable_incentive_scheme.message')
json.leaderboard channel_partners_leaderboard_without_layout_url(id: variable_incentive_scheme.id)