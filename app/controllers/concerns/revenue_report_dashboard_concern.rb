module RevenueReportDashboardConcern

  def project_wise_invoice_details
    @project_wise_total_tentative_amount = DashboardDataProvider.tentative_reports(current_user, params)
    @project_name_hash = {}
    Project.all.each do |p|
      @project_name_hash[p.id.to_s] = p.name
    end
    @total_amount = 0
    @project_wise_total_tentative_amount.each do |k, v|
      @total_amount += v.map{|h| h[:total_tentative_amount] }.sum
    end
  end

  def set_invoice_matchers
    options = {}
  end
end
