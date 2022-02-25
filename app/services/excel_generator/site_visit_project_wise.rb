module ExcelGenerator::SiteVisitProjectWise

  def  self.site_visit_project_wise_csv(current_user, projects, approved_site_visits, scheduled_site_visits, conducted_site_visits)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "SiteVisitProjectWise")
    sheet.insert_row(0, ["Walk-ins (Project Wise)"])
    sheet.insert_row(1, site_visit_project_wise_csv_headers)
    column_size = site_visit_project_wise_csv_headers.size rescue 0
    column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold 
    column_size.times { |x| sheet.row(1).set_format(x, title_format) }
    index = 1
    projects.where(Project.user_based_scope(current_user)).each do |p|
      index = index+1 
      sheet.insert_row(index, [
        p.name.titleize,
        scheduled_site_visits[p.id].try(:count) || 0,
        conducted_site_visits[p.id].try(:count) || 0,
        approved_site_visits[p.id].try(:count) || 0,
      ])
    end
    total_values = [
      I18n.t('global.total'),
      scheduled_site_visits.values&.flatten&.count || 0,
      conducted_site_visits.values&.flatten&.count || 0,
      approved_site_visits.values&.flatten&.count || 0,
    ]
    sheet.insert_row(sheet.last_row_index + 1, total_values)
    sheet.merge_cells(0,0,0,3)
    spreadsheet = StringIO.new 
    file.write spreadsheet
    spreadsheet  
  end

  def self.site_visit_project_wise_csv_headers
    [
      Project.model_name.human,
      "Scheduled #{SiteVisit.model_name.human(count: 2)}",
      "Conducted #{SiteVisit.model_name.human(count: 2)}",
      "Approved #{SiteVisit.model_name.human(count: 2)}",
    ]  
  end
  #code for make excel headers bold
  def self.title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

end
