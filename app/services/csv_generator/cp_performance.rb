module CsvGenerator::CpPerformance

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

end
