require 'spreadsheet'
class ProjectUnitExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ProjectUnitExportWorker.get_column_names)
    ProjectUnit.all.each_with_index do |project_unit, index|
      sheet.insert_row(index+1, ProjectUnitExportWorker.get_project_unit_row(project_unit))
    end
    file_name = "project_unit-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, emails, "Units").deliver
  end

  def self.get_column_names
    [
      "Unit Name",
      "Unit SFDC ID",
      "Status",
      "Available for",
      "Blocked on",
      "Auto Release On",
      "Held On",
      "Applied Discount Rate",
      "Base Rate",
      "Land Rate",
      "Floor Rise",
      "PLC",
      "Clubhouse Amenities Price",
      "Primary User KYC Name",
      "User Name",
      "User Email",
      "User ID (Used for VLOOKUP)",
      "Amount Received"
    ]
  end

  def self.get_project_unit_row(project_unit)
    [
      project_unit.name,
      project_unit.sfdc_id,
      project_unit.status,
      project_unit.available_for,
      project_unit.blocked_on,
      project_unit.auto_release_on,
      project_unit.held_on,
      project_unit.applied_discount_rate,
      project_unit.base_rate,
      project_unit.land_rate,
      project_unit.floor_rise,
      project_unit.premium_location_charges,
      project_unit.clubhouse_amenities_price,
      (project_unit.primary_user_kyc.name rescue "N/A"),
      (project_unit.user.name rescue "N/A"),
      (project_unit.user.email rescue "N/A"),
      project_unit.user_id,
      project_unit.receipts.where(status:"success").sum(&:total_amount)
    ]
  end
end
