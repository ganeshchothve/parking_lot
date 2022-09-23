module BookingDetailDashboardConcern
  def booking_details_counts
    options = set_matcher
    @booking_details_data = DashboardDataProvider.booking_details_data(options)
  end

  def set_matcher
    options = {matcher: {}}
    if params[:dates].present?
      @dates = params[:dates].split(' - ')
      start_date, end_date = @dates
      options[:matcher] = {
        booked_on: {
          "$gte": Date.parse(start_date).beginning_of_day,
          "$lte": Date.parse(end_date).end_of_day
        }
      }
    end
    if params[:project_ids].present?
      options[:matcher][:project_id] = {"$in": params[:project_ids].map{|id| BSON::ObjectId(id) }}
    else
      options[:matcher][:project_id] = {"$in": Project.where(Project.user_based_scope(current_user)).pluck(:_id).uniq }
    end
    if params[:source].present?
      options[:matcher][:source] = params[:source]
    end
    options[:matcher][:booking_portal_client_id] = current_client.id
    options
  end

end