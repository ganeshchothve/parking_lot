module SourcingManagerDashboardConcern

  def dashboard_counts
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || (current_user.project_ids || [])
    fltrs = ActionController::Parameters.new({fltrs: {project_ids: project_ids }})
    @active_partners = SiteVisit.where(booking_portal_client_id: current_client.try(:id)).build_criteria(fltrs).filter_by_scheduled_on(dates).where({"$and": [SiteVisit.user_based_scope(current_user)]}).distinct(:manager_id).count
    @booking_active_partners = BookingDetail.where(booking_portal_client_id: current_client.try(:id)).build_criteria(fltrs).filter_by_booked_on(dates).where({ "$and": [BookingDetail.user_based_scope(current_user), BookingDetail.booking_stages.selector]}).distinct(:manager_id).count
    @raised_invoices = Invoice.where(booking_portal_client_id: current_client.try(:id)).build_criteria(fltrs).filter_by_created_at(dates).where({ "$and": [Invoice.user_based_scope(current_user), status: 'pending_approval']}).count
    @approved_invoices = Invoice.where(booking_portal_client_id: current_client.try(:id)).build_criteria(fltrs).filter_by_created_at(dates).where({ "$and": [Invoice.user_based_scope(current_user), status: 'approved']}).count
  end

  def invoice_summary
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    start_date, end_date = dates.split(' - ')
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
    project_ids = Project.where(booking_portal_client_id: current_client.try(:id)).where(id: {"$in": project_ids}).distinct(:id)
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
    @max_ladders = DashboardDataProvider.incetive_scheme_max_ladders(current_user, @options)
  end

  def cp_performance
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || (current_user.project_ids || [])
    project_ids = Project.where(booking_portal_client_id: current_client.try(:id)).where(id: {"$in": project_ids}).distinct(:id)
    start_date, end_date = @dates.split(' - ')
    if ["superadmin","admin"].include?(current_user.role) #Channel Partner Manager Performance Dashboard for admin and superadmin
      @cps = User.where(role: "cp", booking_portal_client_id: current_client.id).filter_by_is_active("true")
    else
      # @cps = User.filter_by_role("cp").filter_by_userwise_project_ids(current_user)
      @cps = User.filter_by_role("cp").where(manager_id: current_user.id, booking_portal_client_id: current_client.id).filter_by_is_active("true")
    end
    @matcher = {matcher: {created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }, booking_portal_client_id: current_client.id}}
    @matcher[:matcher][:project_id] = {"$in": project_ids} if project_ids.present?
    @leads = DashboardDataProvider.cp_performance_walkins(current_user, @matcher)
    @site_visits = DashboardDataProvider.cp_performance_site_visits(current_user, @matcher)
    @bookings = DashboardDataProvider.cp_performance_bookings(current_user, @matcher)
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::CpPerformance.cp_performance_csv(@cps, @site_visits, @leads, @bookings).string , filename: "cp_performance-#{Date.today}.xls", type: "application/xls" }
    end
  end

  def cp_status
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    start_date, end_date = @dates.split(' - ')
    matcher = {created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }, booking_portal_client_id: current_client.id}
    if ["superadmin","admin"].include?(current_user.role) #Channel Partner Manager Performance Dashboard for admin and superadmin
      @cp_managers = User.where(role: "cp", booking_portal_client_id: current_client.id).filter_by_is_active("true")
    else
      @cp_managers = User.filter_by_role(:cp).where(manager_id: current_user.id, booking_portal_client_id: current_client.id).filter_by_is_active("true")
    end

    @cp_managers_hash = {'No Manager' => 'No Manager'}
    @cp_managers.each do |cp_manager|
      @cp_managers_hash[cp_manager.id] = cp_manager.name
    end

    @data = ChannelPartner.collection.aggregate([
      {
        "$match": matcher
      },
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
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::CpStatus.cp_status_csv(@cp_managers_hash, @channel_partners_manager_status_count, @channel_partners_status_count).string , filename: "cp_status-#{Date.today}.xls", type: "application/xls" }
    end
  end

  def channel_partner_performance_project_wise
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    start_date, end_date = @dates.split(' - ')

    leads_matcher = filter_matcher
    booking_details_matcher = filter_matcher
    site_visits_matcher = filter_matcher

    daterange_filter =  {
      "$gte": Date.parse(start_date).beginning_of_day,
      "$lte": Date.parse(end_date).end_of_day
    }

    leads_matcher[:created_at] = daterange_filter
    booking_details_matcher[:booked_on] = daterange_filter
    site_visits_matcher[:scheduled_on] = daterange_filter

    @leads = Lead.where(Lead.user_based_scope(current_user, params)).where(leads_matcher)
    @site_visits = SiteVisit.where(SiteVisit.user_based_scope(current_user, params)).where(site_visits_matcher)
    @bookings = BookingDetail.where(BookingDetail.user_based_scope(current_user, params)).where(booking_details_matcher)

    @subscribed_count_project_wise = DashboardDataProvider.subscribed_count_project_wise(current_user, interested_project_matcher)
    @leads = @leads.group_by{|p| p.project_id}
    @all_site_visits = @site_visits.group_by{|p| p.project_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.project_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.project_id}
    @pending_site_visits = @site_visits.filter_by_approval_status('pending').group_by{|p| p.project_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.project_id}
    @rejected_site_visits = @site_visits.filter_by_approval_status('rejected').group_by{|p| p.project_id}
    @registration_done_bookings = @bookings.filter_by_registration_done(true).group_by{|p| p.project_id}
    @confirmed_booked_bookings = @bookings.filter_by_status('booked_confirmed').group_by{|p| p.project_id}
    @bookings = @bookings.group_by{|p| p.project_id}
  end

  private

  def filter_matcher
    active_project_ids = Project.filter_by_is_active(true).pluck(:_id)
    matcher = {
      booking_portal_client_id: current_client.id,
      project_id: { "$in": active_project_ids }
    }
    matcher[:project_id] = {"$in": params[:project_ids].map{|id| BSON::ObjectId(id) }} if params[:project_ids].present?
    @projects = Project.where(_id: matcher[:project_id])
    matcher[:channel_partner_id] = params[:channel_partner_id] if params[:channel_partner_id].present?
    matcher[:manager_id] = params[:manager_id].present? ? params[:manager_id] : { "$ne": nil }
    matcher
  end

  def interested_project_matcher
    active_project_ids = Project.filter_by_is_active(true).pluck(:_id)

    ip_matcher = {
      status: 'approved',
      booking_portal_client_id: current_client.id,
      project_id: { "$in": active_project_ids }
    }
    ip_matcher[:project_id] = {"$in": params[:project_ids].map{|id| BSON::ObjectId(id) }} if params[:project_ids].present?

    if params[:dates].present?
      start_date, end_date = params[:dates].split(' - ')
      ip_matcher[:created_at] = {
        "$gte": Date.parse(start_date).beginning_of_day,
        "$lte": Date.parse(end_date).end_of_day
      }
    end
    if params[:channel_partner_id].present?
      channel_partner = ChannelPartner.where(booking_portal_client_id: current_client.try(:id), id: params[:channel_partner_id]).first
      ip_matcher[:user_id] = {'$in': channel_partner.users.distinct(:id)} if channel_partner.present?
    end
    ip_matcher
  end
end
