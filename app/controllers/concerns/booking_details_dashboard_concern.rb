module BookingDetailsDashboardConcern
  extend ActiveSupport::Concern

  def confirmed_bookings_dashboard_report
    @confirmed_bookings = DashboardDataProvider.bookings_with_completed_tasks_list(booking_details_matcher)
  end

  private

  def booking_details_matcher
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

end
