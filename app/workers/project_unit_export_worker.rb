require 'spreadsheet'
class ProjectUnitExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ProjectUnitExportWorker.get_column_names)
    ProjectUnit.where(ProjectUnit.user_based_scope(user)).build_criteria({fltrs: filters}.with_indifferent_access).each_with_index do |project_unit, index|
      sheet.insert_row(index+1, ProjectUnitExportWorker.get_project_unit_row(project_unit))
    end
    file_name = "project_unit-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Units").deliver
  end

  def self.get_column_names
    [
      "ID (Used for Bulk Upload)",
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
      "Floor",
      "Floor Order",
      "Bedrooms",
      "Bathrooms",
      "Unit facing direction",
      "Floor Rise",
      "Agreement Price",
      "All Inclusive Price",
      "Available for",
      "Blocked on",
      "Auto Release On",
      "Comments"
    ]
  end

  def self.get_project_unit_row(project_unit)
    status = project_unit.booking_detail.present? ? project_unit.booking_detail.status : project_unit.status
    [
      project_unit.id.to_s,
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.bedrooms,
      (project_unit.user.lead_id rescue "N/A"),
      (project_unit.user.name rescue "N/A"),
      (project_unit.user.phone rescue "N/A"),
      (project_unit.user.email rescue "N/A"),
      status,
      project_unit.saleable,
      project_unit.carpet,
      project_unit.base_rate,
      project_unit.floor,
      project_unit.floor_order,
      project_unit.bedrooms,
      project_unit.bathrooms,
      project_unit.unit_facing_direction,
      project_unit.floor_rise,
      project_unit.calculate_agreement_price,
      project_unit.calculate_all_inclusive_price,
      project_unit.available_for,
      project_unit.blocked_on,
      project_unit.auto_release_on,
      project_unit.comments
    ]
  end
end
