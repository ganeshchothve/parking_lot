module CsvGenerator::ChannelPartnerPerformance

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

end
