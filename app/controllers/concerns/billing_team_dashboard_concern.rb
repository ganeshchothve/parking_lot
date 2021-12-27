module BillingTeamDashboardConcern

  def billing_team_dashboard
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
  end

  def city_wise_booking_report
    set_matcher
    @project_booking_report = DashboardDataProvider.city_wise_booking_report(current_user, @options)
    @project_name_hash = {}
    Project.each do |p|
      @project_name_hash[p.id.to_s] = p.name
    end
  end

  def project_wise_invoice_summary
    set_matcher
    # TO-DO Send options to project_wise_invoice_data
    @invoice_data = DashboardDataProvider.project_wise_invoice_data(current_user, @options)
  end

  def project_wise_incentive_deduction_summary
    set_matcher
    # TO-DO Send options to project_wise_incentive_deduction_data
    @deduction_data = DashboardDataProvider.project_wise_incentive_deduction_data(current_user, @options)
  end

  def invoice_ageing_report
    set_matcher
    # TO-DO Send options to project_wise_invoice_ageing_data
    @invoice_age_data = DashboardDataProvider.project_wise_invoice_ageing_data(current_user, @options)
  end

  def set_matcher
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    start_date, end_date = @dates.split(' - ')
    @options = {
      matcher: {
        created_at: {
          "$gte": Date.parse(start_date).beginning_of_day, 
          "$lte": Date.parse(end_date).end_of_day 
        }
      }
    }
  end
end