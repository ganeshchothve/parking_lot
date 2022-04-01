module ExcelGenerator::PartnerWisePerformance

  def self.partner_wise_performance_csv(user, leads, bookings, all_site_visits, site_visits, pending_site_visits, approved_site_visits, rejected_site_visits, scheduled_site_visits, conducted_site_visits, manager_ids)

    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "PartnerWisePerformance")
    sheet.insert_row(0, ["Channel Partner Performance (User Wise)"])
    sheet.insert_row(1, partner_wise_performance_csv_headers)
    column_size = partner_wise_performance_csv_headers.size rescue 0
    column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold 
    column_size.times { |x| sheet.row(1).set_format(x, title_format) }
    index = 1
    total_sign_in_count = 0

    users = User.filter_by_role(%w(cp_owner channel_partner)).where(User.user_based_scope(user)).in(manager_ids)

    users.each do |p|
    index = index+1
    total_sign_in_count += (p.sign_in_count || 0)
    sheet.insert_row(index, [
      p&.channel_partner&.name&.titleize,
      p.name.titleize,
      p.sign_in_count || 0,
      leads[p.id].try(:count) || 0,
      scheduled_site_visits[p.id].try(:count) || 0,
      conducted_site_visits[p.id].try(:count) || 0,
      pending_site_visits[p.id].try(:count) || 0,
      approved_site_visits[p.id].try(:count) || 0,
      rejected_site_visits[p.id].try(:count) || 0,
      bookings[p.id].try(:count) || 0,
      (bookings[p.id].try(:pluck, :agreement_price)&.map(&:to_f)&.sum || 0)
    ])
    end
    total_values = [
      I18n.t('global.total'),
      "",
      total_sign_in_count,
      leads.values&.flatten&.count || 0,
      scheduled_site_visits.values&.flatten&.count || 0,
      conducted_site_visits.values&.flatten&.count || 0,
      pending_site_visits.values&.flatten&.count || 0,
      approved_site_visits.values&.flatten&.count || 0,
      rejected_site_visits.values&.flatten&.count || 0,
      bookings.values&.flatten&.count || 0,
      (bookings.values&.flatten&.pluck(:agreement_price)&.map(&:to_f)&.sum || 0)
    ]
    sheet.insert_row(sheet.last_row_index + 1, total_values)
    sheet.merge_cells(0,0,0,9)
    spreadsheet = StringIO.new 
    file.write spreadsheet
    spreadsheet 
  end

  def self.partner_wise_performance_csv_headers
    [
      "#{I18n.t('mongoid.attributes.channel_partner.company_name')}",
      "#{I18n.t("mongoid.attributes.user/role.channel_partner")}/#{I18n.t("mongoid.attributes.user/role.cp_owner")}",
      "Sign In Count",
      Lead.model_name.human(count: 2),
      "Scheduled #{SiteVisit.model_name.human(count: 2)}",
      "Conducted #{SiteVisit.model_name.human(count: 2)}",
      "Pending #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      "Rejected #{SiteVisit.model_name.human(count: 2)}",
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
