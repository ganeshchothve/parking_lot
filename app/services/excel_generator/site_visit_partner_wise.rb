module ExcelGenerator::SiteVisitPartnerWise

  def self.site_visit_partner_wise_csv(user, bookings, all_site_visits, approved_site_visits, scheduled_site_visits, conducted_site_visits, paid_site_visits)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "SiteVisitPartnerWise")
    sheet.insert_row(0, ["Walk-ins (User Wise)"])
    sheet.insert_row(1, site_visit_partner_wise_csv_headers)
    column_size = site_visit_partner_wise_csv_headers.size rescue 0
    column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold 
    column_size.times { |x| sheet.row(1).set_format(x, title_format) }
    index = 1
    User.filter_by_role(%w(cp_owner)).where(User.user_based_scope(user)).each do |p|
      index = index+1
      users = User.where(channel_partner_id: p.channel_partner_id) 
      sheet.insert_row(index, [
        p.channel_partner&.name&.titleize,
        "",
        all_site_visits.values_at(*users.pluck(:id))&.flatten&.compact&.count || 0,
        scheduled_site_visits.values_at(*users.pluck(:id))&.flatten&.compact&.count || 0,
        conducted_site_visits.values_at(*users.pluck(:id))&.flatten&.compact&.count || 0,
        paid_site_visits.values_at(*users.pluck(:id))&.flatten&.compact&.count || 0,
        approved_site_visits.values_at(*users.pluck(:id))&.flatten&.compact&.count || 0,
        bookings.values_at(*users.pluck(:id))&.flatten&.compact&.count || 0
      ])
      index += 1
      sheet.insert_row(index, [
        "",
        p.name&.titleize,
        all_site_visits[p.id].try(:count) || 0,
        scheduled_site_visits[p.id].try(:count) || 0,
        conducted_site_visits[p.id].try(:count) || 0,
        paid_site_visits[p.id].try(:count) || 0,
        approved_site_visits[p.id].try(:count) || 0,
        bookings[p.id].try(:count) || 0
      ])
      users.each do |c|
        next if c.role?('cp_owner')
        index = index+1 
        sheet.insert_row(index, [
          "",
          c.name.titleize,
          all_site_visits[c.id].try(:count) || 0,
          scheduled_site_visits[c.id].try(:count) || 0,
          conducted_site_visits[c.id].try(:count) || 0,
          paid_site_visits[c.id].try(:count) || 0,
          approved_site_visits[c.id].try(:count) || 0,
          bookings[c.id].try(:count) || 0
        ])
      end
    end
    sheet.merge_cells(0,0,0,9)
    spreadsheet = StringIO.new 
    file.write spreadsheet
    spreadsheet 
  end

  def self.site_visit_partner_wise_csv_headers
    [ 
      "Partner Companies",
      "#{I18n.t("mongoid.attributes.user/role.channel_partner")}",
      "All #{SiteVisit.model_name.human(count: 2)}",
      "Scheduled #{SiteVisit.model_name.human(count: 2)}",
      "Conducted #{SiteVisit.model_name.human(count: 2)}",
      "Paid #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
      BookingDetail.model_name.human(count: 2)
    ]  
  end

  #code for make excel headers bold
  def self.title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

end
