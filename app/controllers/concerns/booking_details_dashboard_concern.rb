module BookingDetailsDashboardConcern
  extend ActiveSupport::Concern

  def confirmed_bookings_dashboard_report
    @confirmed_bookings = DashboardDataProvider.bookings_with_completed_tasks_list(booking_details_aggregation_matcher)
  end

  def booking_progress_dashboard_report
    @bookings_progress_data = BookingProgressReport.data(booking_details_queries_matcher)
  end

  private

  def booking_details_aggregation_matcher
    options = {matcher: {}}
    options[:matcher] = { booking_portal_client_id: current_client.id }
    if params[:dates].present?
      @dates = params[:dates].split(' - ')
      start_date, end_date = @dates
      options[:matcher][:created_at] = {
        "$gte": Date.parse(start_date).beginning_of_day,
        "$lte": Date.parse(end_date).end_of_day
      }
    end
    if params[:project_ids].present?
      options[:matcher][:project_id] = {"$in": params[:project_ids].map{|id| BSON::ObjectId(id) }}
    else
      options[:matcher][:project_id] = {"$in": Project.where(Project.user_based_scope(current_user)).pluck(:_id).uniq }
    end
    options
  end

  def booking_details_queries_matcher
    matcher = { booking_portal_client_id: current_client.id, dates: params[:dates], project_ids: params[:project_ids] }
  end

end
