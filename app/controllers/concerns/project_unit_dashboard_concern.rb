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
    options
  end

end
