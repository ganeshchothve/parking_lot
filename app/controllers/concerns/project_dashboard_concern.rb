module ProjectDashboardConcern
  extend ActiveSupport::Concern

  def project_wise_booking_details_counts
    @booking_details_data = DashboardDataProvider.project_wise_booking_details_data(current_user, set_matcher)
  end

  def project_wise_conversion_report
    @conversion_report_data = DashboardDataProvider.project_wise_conversion_report_data(current_user, set_matcher)
  end

  def project_wise_leads_stage_report
    @stage_wise_leads, @lead_stages = DashboardDataProvider.project_wise_lead_stage_leads_count(current_user, set_matcher)
  end

  def project_wise_user_requests_report
    @user_requests_data = DashboardDataProvider.project_wise_user_requests_report_data(current_user, user_requests_report_data_matcher)
  end

  private

  def set_matcher
    options = { booking_portal_client_id: current_client.id }
    if params[:dates].present?
      @dates = params[:dates].split(' - ')
      start_date, end_date = @dates
      options[:created_at] = {
        "$gte": Date.parse(start_date).beginning_of_day,
        "$lte": Date.parse(end_date).end_of_day
      }
    end
    if params[:project_ids].present?
      options[:project_id] = {"$in": params[:project_ids].map{|id| BSON::ObjectId(id) }}
    else
      options[:project_id] = {"$in": Project.where(Project.user_based_scope(current_user)).pluck(:_id).uniq }
    end
    options
  end

  def user_requests_report_data_matcher
    options = {matcher: {}}
    options[:matcher] = { booking_portal_client_id: current_client.id }
    if params[:user_request_fltrs].present?
      options[:group_by] = params[:user_request_fltrs]
    end
    options
  end

end
