module SourcingManagerDashboardConcern

  def dashboard_counts
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
    @active_partners = Lead.build_criteria(fltrs: {created_at: dates, project_ids: project_ids }).where({"$and": [Lead.user_based_scope(current_user)]}).distinct(:manager_id).count
    @booking_active_partners = BookingDetail.build_criteria(fltrs: {created_at: dates, project_ids: project_ids }).where({ "$and": [BookingDetail.user_based_scope(current_user), BookingDetail.booking_stages.selector]}).distinct(:manager_id).count
    @raised_invoices = Invoice.build_criteria(fltrs: {created_at: dates, project_ids: project_ids }).where({ "$and": [Invoice.user_based_scope(current_user), status: 'pending_approval']}).count
    @approved_invoices = Invoice.build_criteria(fltrs: {created_at: dates, project_ids: project_ids }).where({ "$and": [Invoice.user_based_scope(current_user), status: 'approved']}).count
  end

  def invoice_summary
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    start_date, end_date = dates.split(' - ')
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
    project_ids = Project.where(id: {"$in": project_ids}).distinct(:id)
    opt = {}
    opt = {
      matcher:{
        project_id: {"$in": project_ids}
      }
    } if project_ids.present?
    @invoices = DashboardDataProvider.inventive_scheme_performance(current_user, opt)
    @options = {
                matcher:
                {
                  starts_on: {"$lte": Time.at(Date.parse(end_date).end_of_day)}, 
                  ends_on: {"$gte": Time.at(Date.parse(start_date).beginning_of_day)},

                  status: "approved",
                }
              }
    @options[:matcher][:project_id] = {"$in": project_ids} if project_ids.present?
    @max_ladders = DashboardDataProvider.incetive_scheme_max_ladders(@options)
  end

  def cp_performance
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
    project_ids = Project.where(id: {"$in": project_ids}).distinct(:id)
    start_date, end_date = dates.split(' - ')
    @cps = User.where(manager_id: current_user.id)
    @matcher = {matcher: {created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }}}
    @matcher[:matcher][:project_id] = {"$in": project_ids} if project_ids.present?
    @walkins = DashboardDataProvider.cp_performance_walkins(current_user, @matcher)
    @bookings = DashboardDataProvider.cp_performance_bookings(current_user, @matcher)
  end
end