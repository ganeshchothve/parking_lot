module RevenueReportDashboardConcern

  def project_wise_tentative_revenue
    @project_wise_total_tentative_amount={}
    @project_wise_total_tentative_amount = RevenueReportDashboardDataProvider.tentative_reports(current_user, params)
    @project_name_hash = {}
    Project.all.each do |p|
      @project_name_hash[p.id.to_s] = p.name
    end
    @total_amount = 0
    @project_wise_total_tentative_amount.each do |k, v|
      @total_amount += v.map{|h| h[:amount] }.sum
    end
  end

  def project_wise_actual_revenue
    @project_wise_total_invoice_amount={}
    @project_wise_total_invoice_amount = RevenueReportDashboardDataProvider.actual_reports(current_user, params)
    @project_name_hash = {}
    Project.all.each do |p|
      @project_name_hash[p.id.to_s] = p.name
    end

    @status_wise_total_amount = {}
    @project_wise_total_invoice_amount.each do |key, project_wise_count_hash|
      project_wise_count_hash.each do |key, status_wise_count_hash|
        status_wise_count_hash.each do |status, amount|
          if @status_wise_total_amount.has_key?(status)
            @status_wise_total_amount[status] = @status_wise_total_amount[status]+amount
          else
            @status_wise_total_amount[status] = amount
          end
        end
      end
    end

    @project_wise_total_amount = {}
    @project_wise_total_invoice_amount.each do |key, project_wise_count_hash|
      project_wise_count_hash.each do |key, status_wise_count_hash|
        @project_wise_total_amount[key] = status_wise_count_hash.values.sum
      end
    end

    @total_amount = 0
    @total_amount = @project_wise_total_amount.values.sum
  end

end
