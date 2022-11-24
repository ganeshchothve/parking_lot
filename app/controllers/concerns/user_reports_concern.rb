module UserReportsConcern
  extend ActiveSupport::Concern

  #
  # GET /admin/users/portal_stage_chart
  #
  # This method is used in admin dashboard
  #
  def portal_stage_chart
    @data = DashboardData::AdminDataProvider.user_block(current_user)
  end

  #TO DO - move to SourcingManagerDashboardConcern
  def channel_partner_performance
    interested_project_matcher = {status: {'$in': ["approved"]}}
    @dates = params[:dates]
    @interested_project_dates = @dates
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    start_date, end_date = @interested_project_dates.split(' - ') if @interested_project_dates.present?
    active_project_ids = Project.filter_by_is_active(true).pluck(:_id)
    interested_project_matcher[:created_at] =  {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day } if start_date.present? && end_date.present?
    @leads = Lead.where(Lead.user_based_scope(current_user, params)).filter_by_created_at(@dates).filter_by_project_ids(active_project_ids)
    @site_visits = SiteVisit.where(SiteVisit.user_based_scope(current_user, params)).filter_by_scheduled_on(@dates).filter_by_project_ids(active_project_ids)
    @bookings = BookingDetail.booking_stages.where(BookingDetail.user_based_scope(current_user, params)).filter_by_booked_on(@dates).filter_by_project_ids(active_project_ids)
    if params[:project_ids].present?
      project_ids = params["project_ids"].try(:split, ",").try(:flatten)
      project_ids = Project.where(booking_portal_client_id: current_client.try(:id), id: {"$in": project_ids}).filter_by_is_active(true).distinct(:id)
      @leads = @leads.filter_by_project_ids(project_ids)
      @site_visits = @site_visits.filter_by_project_ids(project_ids)
      @bookings = @bookings.filter_by_project_ids(project_ids)
      interested_project_matcher[:project_id] = {'$in': project_ids} if project_ids.present?
    end
    if params[:channel_partner_id].present?
      @leads = @leads.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
      @bookings = @bookings.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
      channel_partner = ChannelPartner.where(booking_portal_client_id: current_client.try(:id), id: params[:channel_partner_id]).first
      interested_project_matcher[:user_id] = {'$in': channel_partner.users.distinct(:id)} if channel_partner.present?
    end
    if params[:manager_id].present?
      @leads = @leads.where(booking_portal_client_id: current_client.try(:id), manager_id: params[:manager_id])
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), manager_id: params[:manager_id])
      @bookings = @bookings.where(booking_portal_client_id: current_client.try(:id), manager_id: params[:manager_id])
    end
    # Exclude leads added by non-channel partner accounts in channel partner performance report
    if params[:manager_id].blank? && params[:channel_partner_id].blank?
      @leads = @leads.ne(manager_id: nil)
      @site_visits = @site_visits.ne(manager_id: nil)
      @bookings = @bookings.ne(manager_id: nil)
    end
    @subscribed_count_project_wise = DashboardDataProvider.subscribed_count_project_wise(current_user, interested_project_matcher)
    @leads = @leads.group_by{|p| p.project_id}
    @all_site_visits = @site_visits.group_by{|p| p.project_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.project_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.project_id}
    @pending_site_visits = @site_visits.filter_by_approval_status('pending').group_by{|p| p.project_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.project_id}
    @rejected_site_visits = @site_visits.filter_by_approval_status('rejected').group_by{|p| p.project_id}
    @bookings = @bookings.group_by{|p| p.project_id}
    @projects = params[:project_ids].present? ? Project.filter_by__id(params[:project_ids]) : Project.all
    @projects = @projects.filter_by_is_active(true)
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::ChannelPartnerPerformance.channel_partner_performance_csv(current_user, @projects, @leads, @bookings, @all_site_visits, @site_visits, @pending_site_visits, @approved_site_visits, @rejected_site_visits, @subscribed_count_project_wise, @scheduled_site_visits, @conducted_site_visits).string , filename: "channel_partner_performance-#{Date.today}.xls", type: "application/xls" }
    end
  end

  #TO DO - move to SourcingManagerDashboardConcern
  def partner_wise_performance
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    @leads = Lead.filter_by_created_at(@dates).where(Lead.user_based_scope(current_user, params))

    @site_visits = SiteVisit.filter_by_scheduled_on(@dates).where(SiteVisit.user_based_scope(current_user, params))
    @bookings = BookingDetail.booking_stages.filter_by_booked_on(@dates).where(BookingDetail.user_based_scope(current_user, params))

    @site_visits_manager_ids = @site_visits.distinct(:manager_id).compact
    @booking_detail_manager_ids = @bookings.distinct(:manager_id).compact
    client_id = current_client.try(:id)
    @manager_ids_criteria = partner_wise_filters(@site_visits_manager_ids, @booking_detail_manager_ids, client_id, params)

    if params[:project_id].present?
      @leads = @leads.where(booking_portal_client_id: current_client.try(:id), project_id: params[:project_id])
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), project_id: params[:project_id])
      @bookings = @bookings.where(booking_portal_client_id: current_client.try(:id), project_id: params[:project_id])
    end
    if params[:channel_partner_id].present?
      @leads = @leads.where(channel_partner_id: params[:channel_partner_id])
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
      @bookings = @bookings.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
    else
      @leads = @leads.ne(manager_id: nil)
      @site_visits = @site_visits.ne(manager_id: nil)
      @bookings = @bookings.ne(manager_id: nil)
    end
    @leads = @leads.group_by{|p| p.manager_id}
    @all_site_visits = @site_visits.ne(manager_id: nil).group_by{|p| p.manager_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.manager_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.manager_id}
    @pending_site_visits = @site_visits.filter_by_approval_status('pending').group_by{|p| p.manager_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.manager_id}
    @rejected_site_visits = @site_visits.filter_by_approval_status('rejected').group_by{|p| p.manager_id}
    @bookings = @bookings.group_by{|p| p.manager_id}
    user = params[:channel_partner_id].present? ? ChannelPartner.where(booking_portal_client_id: current_client.try(:id), id: params[:channel_partner_id]).first&.users&.cp_owner&.first : current_user
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::PartnerWisePerformance.partner_wise_performance_csv(user, @leads, @bookings, @all_site_visits, @site_visits, @pending_site_visits, @approved_site_visits, @rejected_site_visits, @scheduled_site_visits, @conducted_site_visits, @manager_ids_criteria).string , filename: "partner_wise_performance-#{Date.today}.xls", type: "application/xls" }
    end
  end

  def site_visit_project_wise
    @dates = params[:dates]
    @dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if @dates.blank?
    @site_visits = SiteVisit.filter_by_scheduled_on(@dates).where(SiteVisit.user_based_scope(current_user, params))
    @projects = params[:project_ids].present? ? Project.filter_by__id(params[:project_ids]).filter_by_is_active(true) : Project.filter_by_is_active(true)
    if params[:project_ids].present?
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), project_id: {"$in": params[:project_ids]})
    elsif
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), project_id: {"$in": @projects.pluck(:id)})
    end
    if params[:manager_id].present?
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), manager_id: params[:manager_id])
    end
    if params[:channel_partner_id].present?
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
    end
    if params[:manager_id].blank? && params[:channel_partner_id].blank?
      @site_visits = @site_visits.ne(manager_id: nil)
    end
    @all_site_visits = @site_visits.group_by{|p| p.project_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.project_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.project_id}
    @paid_site_visits = @site_visits.filter_by_status('paid').group_by{|p| p.project_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.project_id}
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::SiteVisitProjectWise.site_visit_project_wise_csv(current_user, @projects, @approved_site_visits, @scheduled_site_visits, @conducted_site_visits, @all_site_visits, @paid_site_visits).string , filename: "site_visit_project_wise_csv-#{Date.today}.xls", type: "application/xls" }
    end
  end

  def site_visit_partner_wise
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?

    @site_visits = SiteVisit.filter_by_scheduled_on(dates).where(SiteVisit.user_based_scope(current_user, params))
    @bookings = BookingDetail.booking_stages.filter_by_booked_on(dates).where(BookingDetail.user_based_scope(current_user, params))

    @site_visits_manager_ids = @site_visits.distinct(:manager_id).compact || []
    @booking_detail_manager_ids = @bookings.distinct(:manager_id).compact || []
    client_id = current_client.try(:id)
    @manager_ids_criteria = partner_wise_filters(@site_visits_manager_ids, @booking_detail_manager_ids, client_id, params)

    if params[:project_id].present?
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), project_id: params[:project_id])
      @bookings = @bookings.where(booking_portal_client_id: current_client.try(:id), project_id: params[:project_id])
    end
    if params[:channel_partner_id].present?
      @site_visits = @site_visits.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
      @bookings = @bookings.where(booking_portal_client_id: current_client.try(:id), channel_partner_id: params[:channel_partner_id])
    else
      @site_visits = @site_visits.ne(manager_id: nil)
      @bookings = @bookings.ne(manager_id: nil)
    end
    @all_site_visits = @site_visits.ne(manager_id: nil).group_by{|p| p.manager_id}
    @scheduled_site_visits = @site_visits.filter_by_status('scheduled').group_by{|p| p.manager_id}
    @conducted_site_visits = @site_visits.filter_by_status('conducted').group_by{|p| p.manager_id}
    @paid_site_visits = @site_visits.filter_by_status('paid').group_by{|p| p.manager_id}
    @approved_site_visits = @site_visits.filter_by_approval_status('approved').group_by{|p| p.manager_id}
    @bookings = @bookings.group_by{|p| p.manager_id}
    user = params[:channel_partner_id].present? ? ChannelPartner.where(booking_portal_client_id: current_client.try(:id), id: params[:channel_partner_id]).first&.users&.cp_owner&.first : current_user
    respond_to do |format|
      format.js
      format.xls { send_data ExcelGenerator::SiteVisitPartnerWise.site_visit_partner_wise_csv(user, @bookings, @all_site_visits, @approved_site_visits, @scheduled_site_visits, @conducted_site_visits, @paid_site_visits, @manager_ids_criteria).string , filename: "site_visit_partner_wise-#{Date.today}.xls", type: "application/xls" }
    end
  end

  private

  def partner_wise_filters (site_visit_manager_ids, booking_detail_manager_ids, client_id, params = {})

    manager_ids_with_sv_and_booking = site_visit_manager_ids & booking_detail_manager_ids
    manager_ids_with_sv_or_booking = site_visit_manager_ids || booking_detail_manager_ids
    manager_ids_with_sv_and_no_booking = site_visit_manager_ids - booking_detail_manager_ids
    manager_ids_with_booking_and_no_sv = booking_detail_manager_ids - site_visit_manager_ids

    user_ids = if params[:active_walkins] == 'true' && params[:active_bookings] == 'true'
      manager_ids_with_sv_and_booking
    elsif params[:active_walkins] == 'true' && params[:active_bookings] == 'false'
      manager_ids_with_sv_and_no_booking
    elsif params[:active_walkins] == 'false' && params[:active_bookings] == 'true'
      manager_ids_with_booking_and_no_sv
    elsif params[:active_walkins] == 'false' && params[:active_bookings] == 'false'
      User.where(booking_portal_client_id: client_id).nin(id: manager_ids_with_sv_or_booking).distinct(:id)
    elsif params[:active_walkins] == 'true' && params[:active_bookings] == ''
      User.where(booking_portal_client_id: client_id).in(id: site_visit_manager_ids).distinct(:id)
    elsif params[:active_walkins] == 'false' && params[:active_bookings] == ''
      User.where(booking_portal_client_id: client_id).nin(id: site_visit_manager_ids).distinct(:id)
    elsif params[:active_walkins] == '' && params[:active_bookings] == 'true'
      User.where(booking_portal_client_id: client_id).in(id: booking_detail_manager_ids).distinct(:id)
    elsif params[:active_walkins] == '' && params[:active_bookings] == 'false'
      User.where(booking_portal_client_id: client_id).nin(id: booking_detail_manager_ids).distinct(:id)
    else
      User.where(booking_portal_client_id: client_id).filter_by_role(%w(cp_owner channel_partner)).distinct(:id)
    end

    manager_ids = {id: user_ids}
    manager_ids
  end

end
