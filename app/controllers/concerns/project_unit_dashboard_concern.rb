module ProjectUnitDashboardConcern
  extend ActiveSupport::Concern

  def project_units_inventory_report
    @inventory_data = DashboardDataProvider.project_units_inventory_report_data(current_user, project_units_matcher)
  end

  def project_units_collection_report
    @collection_data = DashboardDataProvider.project_unit_collection_report_data(current_user, project_units_matcher)
  end

  def project_units_typology_report
    @typology_and_inventory_summary_data = DashboardDataProvider.typology_and_inventory_summary(project_units_matcher)
  end

  def configuration_wise_token_report
    options = project_units_matcher
    options[:is_token_report] = true
    @typology_and_inventory_summary_data = DashboardDataProvider.typology_and_inventory_summary(options)
  end

  private

  def project_units_matcher
    options = {matcher: {}}
    options[:matcher] = { booking_portal_client_id: current_client.id }
    if params.dig(:unit_fltrs, :group_by).present?
      options[:group_by] = params.dig(:unit_fltrs, :group_by)
    end
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
