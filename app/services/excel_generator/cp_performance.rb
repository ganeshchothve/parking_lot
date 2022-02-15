module ExcelGenerator::CpPerformance

  def self.cp_performance_csv(cps, site_visits, leads, bookings)

    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "CpPerformance")
    sheet.insert_row(0, ["Channel Partner Manager Performance"])
    sheet.insert_row(1, cp_performance_csv_headers)
    column_size = cp_performance_csv_headers.size rescue 0
    column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold 
    column_size.times { |x| sheet.row(1).set_format(x, title_format) }
    index = 1
    cps.each do |cp|
     index = index+1 
     sheet.insert_row(index, [
      cp.name,
      leads[cp.id] || 0,
      site_visits.dig('scheduled', cp.id.to_s) || 0,
      site_visits.dig('conducted', cp.id.to_s) || 0,
      site_visits.dig('pending', cp.id.to_s) || 0,
      site_visits.dig('approved', cp.id.to_s) || 0,
      site_visits.dig('rejected', cp.id.to_s) || 0,
      bookings.dig(cp.id, :count) || 0,
      bookings.dig(cp.id, :sales_revenue) || 0
    ])
    end
    sheet.merge_cells(0,0,0,8)
    file_name = "cp_performance-#{SecureRandom.hex}.xls"
    spreadsheet = StringIO.new 
    file.write spreadsheet
    spreadsheet
  end

  def self.cp_performance_csv_headers
    [
      I18n.t("mongoid.attributes.user/role.cp"),
      Lead.model_name.human(count: 2),
      "Scheduled #{SiteVisit.model_name.human(count: 2)}",
      "Conducted #{SiteVisit.model_name.human(count: 2)}",
      "Pending #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      "Rejected #{SiteVisit.model_name.human(count: 2)}",
      BookingDetail.model_name.human(count: 2),
      I18n.t('mongoid.attributes.booking_detail.agreement_price')
    ]
  end

  #code for make excel headers bold
  def self.title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

end
