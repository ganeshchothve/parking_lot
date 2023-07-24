module ReceiptDashboardConcern
  extend ActiveSupport::Concern

  def receipts_details_report
    @receipt_details_data = DashboardDataProvider.receipt_details_data(current_user, receipts_dashboard_matcher)
  end

  private

  def receipts_dashboard_matcher
    options = {matcher: {}}
    options[:matcher] = { booking_portal_client_id: current_client.id }
    if params.dig(:receipt_fltrs, :group_by).present?
      options[:group_by] = params.dig(:receipt_fltrs, :group_by)
    end
    options
  end

end
