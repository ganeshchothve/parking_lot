require 'spreadsheet'
class ProjectUnitMisReportWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ProjectUnitMisReportWorker.get_column_names)
    ProjectUnit.in(status: ProjectUnit.booking_stages).each_with_index do |project_unit, index|
      sheet.insert_row(index+1, ProjectUnitMisReportWorker.get_project_unit_row(project_unit))
    end
    file_name = "project_unit_mis-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Units").deliver
  end

  def self.get_column_names
    [
      "Unit Name",
      "Unit Type",
      "Type of Apartment",
      "User Name",
      "User Email",
      "User Phone",
      "Status",
      "Saleable",
      "Carpet",
      "Base Rate",
      "Floor Rise",
      "Agreement price",
      "All Inclusive Price",
      "Available for",
      "Blocked on",
      "Auto Release On"
    ]
  end

  def self.get_project_unit_row(project_unit)
    [
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.bedrooms,
      (project_unit.user.name rescue "N/A"),
      (project_unit.user.email rescue "N/A"),
      (project_unit.user.phone rescue "N/A"),
      project_unit.status,
      project_unit.saleable,
      project_unit.carpet,
      project_unit.base_rate,
      project_unit.floor_rise,
      project_unit.agreement_price,
      project_unit.all_inclusive_price,

      project_unit.available_for,
      project_unit.blocked_on,
      project_unit.auto_release_on
    ]
  end
end
