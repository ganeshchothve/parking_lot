module ChannelPartnerDashboardConcern
  # TO-DO - Add filters for first five boxes

  def channel_partner_dashboard_counts
    #Need refactoring
    dates = params[:dates]
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
    project_ids = Project.where(id: {"$in": project_ids}).distinct(:id) || []

    filters = if dates.present? || project_ids.present?
                {fltrs: {created_at: dates, project_ids: project_ids}}
              else
                {}
              end
    if dates.present? || project_ids.present?
      start_date, end_date = dates.split(' - ')
      options = {
        matcher: {
          created_at: {
            "$gte": Date.parse(start_date).beginning_of_day,
            "$lte": Date.parse(end_date).end_of_day
          }
        }
      }
      options[:matcher][:project_id] = {"$in": project_ids} if project_ids.present?
    else
      options = {}
    end
    @receipts = current_user.receipts.build_criteria(filters).paginate(page: params[:page] || 1, per_page: params[:per_page])

    @total_buyers = DashboardDataProvider.total_buyers(current_user, filters)
    #@grouped_receipts = DashboardDataProvider.receipts_group_by(current_user, options)
    #
    # Payments section
    @booking_count = BookingDetail.where(BookingDetail.user_based_scope(current_user)).build_criteria(filters).count
    @registration_done_booking_count = BookingDetail.where(BookingDetail.user_based_scope(current_user)).build_criteria(filters).filter_by_tasks_completed('registration_done').count
    @cancelled_booking_count = BookingDetail.where(BookingDetail.user_based_scope(current_user)).build_criteria(filters).in(status: %w(cancelled)).count
    @confirmed_booking_count = BookingDetail.build_criteria(filters).where(BookingDetail.user_based_scope(current_user)).booked_confirmed.count
    #
    # Graph section
    @lead_data = DashboardDataProvider.lead_group_by(current_user, options)
    @data = {
      booked_leads: @lead_data['booked'],
      not_booked_leads: @lead_data['not_booked'],
      total_bookings: @booking_count,
      confirmed_bookings: @confirmed_booking_count,
      registration_done_bookings: @registration_done_booking_count
    }
    @data_labels = get_labels(@data)
    #
    # Incentives section
    @incentive_approved = Invoice.where(manager_id: current_user.id, status: 'approved').build_criteria(filters).count
    @incentive_raised = Invoice.where(manager_id: current_user.id, status: 'pending_approval').build_criteria(filters).count
    @bookings_eligible_for_brokerage = BookingDetail.build_criteria(filters).where(BookingDetail.user_based_scope(current_user)).incentive_eligible.count
    @bookins_not_eligible_for_brokerage = BookingDetail.build_criteria(filters).where(BookingDetail.user_based_scope(current_user)).where(status: {"$in": %w(scheme_approved blocked booked_tentative booked_confirmed)}).filter_by_tasks_pending_tracked_by('system').count
    # @incentive_pending_bookings = DashboardDataProvider.incentive_pending_bookings(current_user, filters)
    # @bookings_with_incentive_generated = Invoice.where(Invoice.user_based_scope(current_user)).build_criteria(filters).distinct(:booking_detail_id).count
    @booking_count_booking_stages = BookingDetail.where(BookingDetail.user_based_scope(current_user)).build_criteria(filters).booking_stages.count
    @conversion_rate = DashboardDataProvider.conversion_ratio(current_user, filters)
  end

  def project_wise_summary
    dates = params[:dates]
    if dates.present?
      start_date, end_date = dates.split(" - ")
      options = {
        matcher: {
          created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }
        }
      }
    else
      options = {}
    end
    @projects_leads = DashboardDataProvider.project_wise_leads_count(current_user, options)
    @projects_booking_data = DashboardDataProvider.project_wise_booking_data(current_user, options)
  end

  def incentive_plans_started
    @project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
  end

  def incentive_plans_summary
    dates = params[:dates]
    dates = (Date.today - 6.months).strftime("%d/%m/%Y") + " - " + Date.today.strftime("%d/%m/%Y") if dates.blank?
    project_ids = params["project_ids"].try(:split, ",").try(:flatten) || []
    project_ids = Project.where(id: {"$in": project_ids}).distinct(:id)
    @all_schemes = IncentiveScheme.build_criteria(fltrs: {date_range: dates, project_ids: project_ids, status: 'approved'}).in(tier_id: [nil, '', current_user.tier_id])
  end

  def project_wise_leads
    dates = params[:dates]
    if dates.present?
      start_date, end_date = dates.split(" - ")
      options = {
        matcher: {
          created_at: {"$gte": Date.parse(start_date).beginning_of_day, "$lte": Date.parse(end_date).end_of_day }
        }
      }
    else
      options = {}
    end
    @projects_leads = DashboardDataProvider.project_wise_leads_count(current_user, options)
    project_ids = @projects_leads.try(:[], 'project_wise')&.sort {|x, y| y.last.try(:[], 'count').to_i <=> x.last.try(:[], 'count').to_i}&.first(4)&.collect{|x| x&.first} || []
    options[:matcher] ||= {}
    options[:matcher].merge!({ project_id: { '$in': project_ids } })
    @stage_wise_leads = DashboardDataProvider.lead_stage_project_wise_leads_count(current_user, options)
  end

  def cp_variable_incentive_scheme_report
    options = {}
    options.merge!(user_id: current_user.id.to_s)
    @incentive_data = VariableIncentiveSchemeCalculator.channel_partner_incentive(options)
  end

  private

  def get_labels(data)
    labels = Array.new
    data.keys.each do |key|
      labels << [t("dashboard.channel_partner.data.#{key}.label"), t("dashboard.channel_partner.data.#{key}.sub_label")]
    end
    labels
  end
end
