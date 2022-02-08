module ExcelGenerator::ChannelPartnerPerformance

  def self.channel_partner_performance_csv(current_user, projects, leads, bookings, all_site_visits, site_visits, pending_site_visits, approved_site_visits, rejected_site_visits, subscribed_count_project_wise)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "ChannelPartnerPerformance")
    sheet.insert_row(0, ["Channel Partner Performance (Project Wise)"])
    sheet.insert_row(1, channel_partner_performance_csv_headers)
    column_size = channel_partner_performance_csv_headers.size rescue 0
    column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold 
    column_size.times { |x| sheet.row(1).set_format(x, title_format) }
    index = 1
    projects.where(Project.user_based_scope(current_user)).each do |p|
      index = index+1 
      sheet.insert_row(index, [
        p.name.titleize,
        leads[p.id].try(:count) || 0, 
        pending_site_visits[p.id].try(:count) || 0,
        approved_site_visits[p.id].try(:count) || 0,
        rejected_site_visits[p.id].try(:count) || 0,
        subscribed_count_project_wise[p.id] || 0,
        bookings[p.id].try(:count) || 0,
        (bookings[p.id].try(:pluck, :agreement_price)&.map(&:to_f)&.sum || 0) 
      ])
    end
    total_values = [
      I18n.t('global.total'),
      leads.values&.flatten&.count || 0,
      pending_site_visits.values&.flatten&.count || 0,
      approved_site_visits.values&.flatten&.count || 0,
      rejected_site_visits.values&.flatten&.count || 0,
      subscribed_count_project_wise&.values&.sum || 0,
      bookings.values&.flatten&.count || 0,
      (bookings.values&.flatten&.pluck(:agreement_price)&.map(&:to_f)&.sum || 0)
    ]
    sheet.insert_row(sheet.last_row_index + 1, total_values)
    sheet.merge_cells(0,0,0,6)
    spreadsheet = StringIO.new 
    file.write spreadsheet
    spreadsheet  
  end

  def self.channel_partner_performance_csv_headers
    [
      Project.model_name.human,
      Lead.model_name.human(count: 2),
      "Pending #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      "Rejected #{SiteVisit.model_name.human(count: 2)}",
      I18n.t("mongoid.attributes.interested_project/status.subscribed"),
      BookingDetail.model_name.human(count: 2),
      "Total #{I18n.t('mongoid.attributes.booking_detail.agreement_price')}"
    ]  
  end

  #code for make excel headers bold
  def self.title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

end
