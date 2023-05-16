module ProjectDashboardConcern
  extend ActiveSupport::Concern

  def project_wise_conversion_report
    options = set_matcher
    @conversion_report_data = DashboardDataProvider.project_wise_conversion_report_data(current_user, options)
  end

  def set_matcher
    options = {matcher: {}}
    if params[:dates].present?
      @dates = params[:dates].split(' - ')
      start_date, end_date = @dates
      options[:matcher] = {
        created_date: {
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
    options[:matcher][:booking_portal_client_id] = current_client.id
    options
  end

end
