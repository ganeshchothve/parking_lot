json.current_page @projects.current_page
json.per_page @projects.per_page
json.total_entries @projects.total_entries

json.entries @projects do |project|
  json.extract! project, 'name', '_id', 'developer_name', 'project_type', 'category', 'configurations', 'rera_registration_no', 'micro_market', 'city', 'region', 'project_segment', 'sv_incentive', 'spot_booking_incentive', 'pre_reg_incentive_percentage', 'pre_reg_min_bookings', 'hot', 'mobile_cover_photo_url', 'cover_photo_url', 'cp_subscription_count'

  json.is_subscribed project.is_subscribed(current_user)

  # Actions enabled on project
  json.subscription_enabled policy([current_user_role_group, InterestedProject.new(project: project, user: current_user)]).create?
  json.walkin_enabled policy([current_user_role_group, Lead.new(project: project)]).new?
  json.bookings_enabled policy([current_user_role_group, BookingDetail.new(project: project, user: User.new, lead: Lead.new(project: project))]).show_add_booking_link?
  json.invoicing_enabled policy([current_user_role_group, Invoice.new(project: project)]).new?

  json.assets project.assets do |asset|
    json.extract! asset, :document_type, :_id, :file, :file_name, :file_size
  end
  json.videos project.videos do |video|
    json.extract! video, :_id, :description, :embedded_video, :thumbnail
  end
end
