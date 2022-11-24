module BillingTeamDashboardConcern

  def billing_team_dashboard
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
  end

  def city_wise_booking_report
    matcher = set_city_wise_report_matcher
    @project_booking_report = DashboardDataProvider.city_wise_booking_report(current_user, matcher)
    @project_name_hash = {}
    Project.where(booking_portal_client_id: current_client.try(:id)).each do |p|
      @project_name_hash[p.id.to_s] = p.name
    end
    @total_booking = 0
    @project_booking_report.each do |k, v|
      @total_booking += v.map{|h| h[:bookings_count]  }.sum
    end
  end

  def project_wise_invoice_summary
    set_matcher
    # TO-DO Send options to project_wise_invoice_data
    @invoice_data = DashboardDataProvider.project_wise_invoice_data(current_user, @options)
    @invoice_data = @invoice_data.delete_if {|x| x[:project_name] == nil }
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

  def set_city_wise_report_matcher
    options = {}
    @city_wise_dates = params[:dates]
    if @city_wise_dates.present?
      start_date, end_date = @city_wise_dates.split(' - ')
      options = {
        booked_on: {
          "$gte": Date.parse(start_date).beginning_of_day,
          "$lte": Date.parse(end_date).end_of_day
        }
      }
    end
    if params[:project_ids].present?
      options[:project_id] = { "$in": params[:project_ids].map { |id| BSON::ObjectId(id) } }
    else
      options[:project_id] = { "$in": Project.all.pluck(:id) }
    end
    options[:status] = {"$in": ["blocked", "under_negotiation", "booked_tentative", "booked_confirmed", "cancelled"]}
    options[:booking_portal_client_id] = current_client.id
    options.with_indifferent_access
  end

  def variable_incentive_scheme_report
    options = {}
    options.merge!(user_id: params[:user_id]) if params[:user_id].present?
    @incentive_data = VariableIncentiveSchemeCalculator.channel_partner_incentive(options)
  end
end