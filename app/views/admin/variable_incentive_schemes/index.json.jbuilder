if device_type?('mobile')
  json.current_page @variable_incentive_schemes.current_page
  json.per_page @variable_incentive_schemes.per_page
  json.total_entries @variable_incentive_schemes.total_entries
end

json.entries @variable_incentive_schemes do |vis|
  json.extract! vis, 'id', 'name', 'start_date', 'end_date', 'terms_and_conditions', 'total_bookings'
  json.subscribed_count vis.subscriptions.count
  json.total_earning_potential total_earning_potential(vis)
  json.projects vis.projects.collect { |pr| pr.name }
  json.can_subscribe can_subscribe?(vis)
end