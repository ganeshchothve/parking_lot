json.current_page @projects.current_page
json.per_page @projects.per_page
json.total_entries @projects.total_entries

json.entries @projects do |project|
  json.extract! project, 'name', '_id', 'developer_name', 'project_type', 'category', 'configurations', 'rera_registration_no', 'micro_market', 'city', 'region', 'project_segment', 'sv_incentive', 'spot_booking_incentive', 'pre_reg_incentive_percentage', 'pre_reg_min_bookings', 'hot', 'mobile_cover_photo_url', 'cover_photo_url', 'cp_subscription_count'

  json.is_subscribed project.is_subscribed(current_user)

  json.assets project.assets do |asset|
    json.extract! asset, :document_type, :_id, :file, :file_name, :file_size
  end
  json.videos project.videos do |video|
    json.extract! video, :_id, :description, :embedded_video, :thumbnail
  end
end
