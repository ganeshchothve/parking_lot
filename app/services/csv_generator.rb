module CsvGenerator

  def  self.cp_status_csv(cp_managers_hash, channel_partners_manager_status_count, channel_partners_status_count)
    attributes = cp_status_csv_headers
    csv_str = CSV.generate(headers: true) do |csv|
      csv << attributes
      cp_managers_hash.each do |cp_id, cp_name|
        csv << [
          cp_name,
          (channel_partners_manager_status_count[cp_id]["inactive"] || 0),
          (channel_partners_manager_status_count[cp_id]["active"] || 0),
          (channel_partners_manager_status_count[cp_id]["pending"] || 0),
          (channel_partners_manager_status_count[cp_id]["rejected"] || 0),
          (channel_partners_manager_status_count[cp_id]["count"] || 0)
        ]
      end
      total_values = ["Total"]
      %w(inactive active pending rejected total).each do |status| 
        total_values << channel_partners_status_count[status] || 0
      end
      csv << total_values
    end
    csv_str
  end

  def self.cp_status_csv_headers
    [
      I18n.t("mongoid.attributes.user/role.cp"),
      I18n.t("dashboard.cp_admin.cp_status.inactive_html"),
      I18n.t("dashboard.cp_admin.cp_status.active_html"),
      I18n.t("dashboard.cp_admin.cp_status.pending_html"),
      I18n.t("dashboard.cp_admin.cp_status.rejected_html"),
      I18n.t("global.total"),
    ]
  end

  def self.cp_performance_csv(cps, site_visits, leads, bookings)
    attributes = cp_performance_csv_headers
    csv_str = CSV.generate(headers: true) do |csv|
      csv << attributes
      cps.each do |cp|
        csv << [
          cp.name,
          leads[cp.id] || 0,
          site_visits.dig('pending', cp.id.to_s) || 0,
          site_visits.dig('approved', cp.id.to_s) || 0,
          site_visits.dig('rejected', cp.id.to_s) || 0,
          bookings.dig(cp.id, :count) || 0,
          bookings.dig(cp.id, :sales_revenue) || 0
        ]
      end
    end
    csv_str
  end

  def self.cp_performance_csv_headers
    [
      I18n.t("mongoid.attributes.user/role.cp"),
      Lead.model_name.human(count: 2),
      "Pending #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      "Rejected #{SiteVisit.model_name.human(count: 2)}",
      BookingDetail.model_name.human(count: 2),
      I18n.t('mongoid.attributes.booking_detail.agreement_price')
    ]
  end

  def self.channel_partner_performance_csv(current_user, projects, leads, bookings, all_site_visits, site_visits, pending_site_visits, approved_site_visits, rejected_site_visits)
    attributes = channel_partner_performance_csv_headers
    csv_str = CSV.generate(headers: true) do |csv|
      csv << attributes
      projects.where(Project.user_based_scope(current_user)).each do |p|
        csv << [
          p.name.titleize,
          leads[p.id].try(:count) || 0, 
          pending_site_visits[p.id].try(:count) || 0,
          approved_site_visits[p.id].try(:count) || 0,
          rejected_site_visits[p.id].try(:count) || 0,
          bookings[p.id].try(:count) || 0,
          (bookings[p.id].try(:pluck, :agreement_price)&.map(&:to_f)&.sum || 0) 
        ]
      end
      csv << [
        I18n.t('global.total'),
        leads.values&.flatten&.count || 0,
        pending_site_visits.values&.flatten&.count || 0,
        approved_site_visits.values&.flatten&.count || 0,
        rejected_site_visits.values&.flatten&.count || 0,
        bookings.values&.flatten&.count || 0,
        (bookings.values&.flatten&.pluck(:agreement_price)&.map(&:to_f)&.sum || 0)
      ]
    end
    csv_str   
  end

  def self.channel_partner_performance_csv_headers
    [
      Project.model_name.human,
      Lead.model_name.human(count: 2),
      "Pending #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      "Rejected #{SiteVisit.model_name.human(count: 2)}",
      BookingDetail.model_name.human(count: 2),
      "Total #{I18n.t('mongoid.attributes.booking_detail.agreement_price')}"
    ]  
  end

  def self.partner_wise_performance_csv(user, leads, bookings, all_site_visits, site_visits, pending_site_visits, approved_site_visits, rejected_site_visits)
    attributes = channel_partner_performance_csv_headers
    csv_str = CSV.generate(headers: true) do |csv|
      csv << attributes
       User.filter_by_role(%w(cp_owner channel_partner)).where(User.user_based_scope(user)).each do |p|
        csv << [
          p.name.titleize,
          leads[p.id].try(:count) || 0, 
          pending_site_visits[p.id].try(:count) || 0,
          approved_site_visits[p.id].try(:count) || 0,
          rejected_site_visits[p.id].try(:count) || 0,
          bookings[p.id].try(:count) || 0,
          (bookings[p.id].try(:pluck, :agreement_price)&.map(&:to_f)&.sum || 0) 
        ]
      end
      csv << [
        I18n.t('global.total'),
        leads.values&.flatten&.count || 0,
        pending_site_visits.values&.flatten&.count || 0,
        approved_site_visits.values&.flatten&.count || 0,
        rejected_site_visits.values&.flatten&.count || 0,
        bookings.values&.flatten&.count || 0,
        (bookings.values&.flatten&.pluck(:agreement_price)&.map(&:to_f)&.sum || 0)
      ]
    end
    csv_str 
  end

  def self.partner_wise_performance_csv_headers
    [
      I18n.t("mongoid.attributes.user/role.cp_owner"),
      Lead.model_name.human(count: 2),
      "Pending #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      "Rejected #{SiteVisit.model_name.human(count: 2)}",
      BookingDetail.model_name.human(count: 2),
      "Total #{I18n.t('mongoid.attributes.booking_detail.agreement_price')}"
    ]  
  end

end
