require 'spreadsheet'
class ProjectUnitExportWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ProjectUnitExportWorker.get_column_names)
    ProjectUnit.all.each_with_index do |project_unit, index|
      sheet.insert_row(index+1, ProjectUnitExportWorker.get_project_unit_row(project_unit))
    end
    file_name = "project_unit-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Units").deliver
  end

  def self.get_column_names
    [
      "Unit Name",
      "Unit Type",
      "Type of Apartment",
      "Sell.Do Lead ID",
      "User Name",
      "User Phone",
      "User Email",
      "Status",
      "Saleable",
      "Carpet",
      "Base Rate",
      "Floor Rise",
      "Current Due",
      "Total amount paid",
      "Pending balance",
      "Available for",
      "Blocked on",
      "Auto Release On",
      "Ageing"
    ]
  end

  def self.get_project_unit_row(project_unit)
    [
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.bedrooms,
      (project_unit.user.lead_id rescue "N/A"),
      (project_unit.user.name rescue "N/A"),
      (project_unit.user.phone rescue "N/A"),
      (project_unit.user.email rescue "N/A"),
      project_unit.status,
      project_unit.saleable,
      project_unit.carpet,
      project_unit.base_rate,
      project_unit.floor_rise,
      project_unit.pending_balance({strict: true}),
      project_unit.total_amount_paid,
      project_unit.pending_balance,
      project_unit.available_for,
      project_unit.blocked_on,
      project_unit.auto_release_on,
      project_unit.ageing
    ]
  end
end
