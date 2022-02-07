module CsvGenerator::PartnerWisePerformance

  def self.partner_wise_performance_csv(user, leads, bookings, all_site_visits, site_visits, pending_site_visits, approved_site_visits, rejected_site_visits)
    attributes = partner_wise_performance_csv_headers
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
