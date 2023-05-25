module ProjectUnitDashboardConcern
  extend ActiveSupport::Concern

  def project_units_inventory_report
    @inventory_data = DashboardDataProvider.project_units_inventory_report_data(current_user, project_units_inventory_matcher)
  end

  def project_units_collection_report
    @collection_data = DashboardDataProvider.project_unit_collection_report_data(current_user)
  end

  private

  def project_units_inventory_matcher
    options = {matcher: {}}
    options[:matcher] = { booking_portal_client_id: current_client.id }
    if params.dig(:unit_fltrs, :group_by).present?
      options[:group_by] = params.dig(:unit_fltrs, :group_by)
    end
    if params[:project_ids].present?
      options[:matcher][:project_id] = {"$in": params[:project_ids].map{|id| BSON::ObjectId(id) }}
    else
      options[:matcher][:project_id] = {"$in": Project.where(Project.user_based_scope(current_user)).pluck(:_id).uniq }
    end
    options
  end

end
