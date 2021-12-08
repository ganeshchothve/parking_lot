module SourcingManagerDashboardConcern

  def dashboard_counts
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || (current_user.project_ids || [])
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
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || (current_user.project_ids || [])
    project_ids = Project.where(id: {"$in": project_ids}).distinct(:id)
    start_date, end_date = dates.split(' - ')
    if ["superadmin","admin"].include?(current_user.role) #Channel Partner Manager Performance Dashboard for admin and superadmin
      @cps = User.where(role: "cp")
    else
      # @cps = User.filter_by_role("cp").filter_by_userwise_project_ids(current_user)
      @cps = User.filter_by_role("cp").where(manager_id: current_user.id)
    end
    @matcher = {matcher: {created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }}}
    @matcher[:matcher][:project_id] = {"$in": project_ids} if project_ids.present?
    @leads = DashboardDataProvider.cp_performance_walkins(current_user, @matcher)
    @site_visits = DashboardDataProvider.cp_performance_site_visits(current_user, @matcher)
    @bookings = DashboardDataProvider.cp_performance_bookings(current_user, @matcher)
  end

  def cp_status
    if ["superadmin","admin"].include?(current_user.role) #Channel Partner Manager Performance Dashboard for admin and superadmin
      @cp_managers = User.where(role: "cp")
    else
      @cp_managers = User.filter_by_role(:cp).where(manager_id: current_user.id)
    end
    
    @cp_managers_hash = {'No Manager' => 'No Manager'}
    @cp_managers.each do |cp_manager|
      @cp_managers_hash[cp_manager.id] = cp_manager.name
    end


    @data = ChannelPartner.collection.aggregate([
      {
        '$project': {
          'first_name': '$first_name',
          'status': '$status',
          'id': '$id',
          'manager_id': '$manager_id'
        }},
        {
        '$group': {
          _id: {
            'manager_id': '$manager_id',
            'status': "$status"
          },
          count: {
          '$sum': 1
          }
        }
      }
    ]).to_a

    @channel_partners_manager_status_count = {}
    @data.each do |channel_partner_data|
      key = channel_partner_data['_id']['manager_id'] || 'No Manager'
      @channel_partners_manager_status_count[key] ||= {}
      @channel_partners_manager_status_count[key][channel_partner_data["_id"]["status"]] ||= 0
      @channel_partners_manager_status_count[key][channel_partner_data["_id"]["status"]] += channel_partner_data["count"]
      @channel_partners_manager_status_count[key]["count"] ||= 0
      @channel_partners_manager_status_count[key]["count"] += channel_partner_data["count"]
    end

    @channel_partners_status_count = @data.group_by {|x| x['_id']['status']}.inject({}) do |hsh, (k, v)|
      hsh[k] = v.map{|x| x['count']}.inject(:+)
      hsh
    end
    @channel_partners_status_count['total'] = @channel_partners_status_count.values.inject(:+)
  end
end
