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
      "Unit Type",
      "Unit Number",
      "Unit SFDC ID",
      "Status",
      "Available for",
      "Blocked on",
      "Auto Release On",
      "Held On",
      "Saleable",
      "Carpet",
      "Applied Discount Rate",
      "Base Rate",
      "Land Rate",
      "Floor Rise",
      "Land price",
      "Construction price",
      "TDS amount",
      "GST on additional charges",
      "GST on agreement price",
      "Sub total",
      "All inclusive price",
      "Pending balance",
      "Total amount paid",
      "Agreement price",
      "PLC",
      "Clubhouse Amenities Price",
      "Water/Electricity/Power Backup",
      "City infrastructure charges",
      "Advance Maintenance charges",
      "Club house & amenities Charges",
      "Corpus Fund",
      "Primary User KYC Name",
      "User Name",
      "User Email",
      "User Phone",
      "User ID (Used for VLOOKUP)",
      "SellDo Lead ID",
      "Amount Received",
      "Current Due",
      "Ageing"
    ]
  end

  def self.get_project_unit_row(project_unit)
    [
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.name.split("|")[0].split("-")[1].strip,
      project_unit.sfdc_id,
      project_unit.status,
      project_unit.available_for,
      project_unit.blocked_on,
      project_unit.auto_release_on,
      project_unit.held_on,
      project_unit.saleable,
      project_unit.carpet,
      project_unit.applied_discount_rate,
      project_unit.base_rate,
      project_unit.land_rate,
      project_unit.floor_rise,
      project_unit.land_price,
      project_unit.construction_price,
      project_unit.tds_amount,
      project_unit.gst_on_additional_charges,
      project_unit.gst_on_agreement_price,
      project_unit.sub_total,
      project_unit.all_inclusive_price,
      project_unit.pending_balance,
      project_unit.total_amount_paid,
      project_unit.agreement_price,
      project_unit.premium_location_charges,
      project_unit.clubhouse_amenities_price,
      project_unit.wep_price.round(2),
      project_unit.city_infrastructure_fund.round(2),
      project_unit.advance_maintenance_charges.round(2),
      "125000",
      project_unit.corpus_fund.round(2),
      (project_unit.primary_user_kyc.name rescue "N/A"),
      (project_unit.user.name rescue "N/A"),
      (project_unit.user.email rescue "N/A"),
      (project_unit.user.phone rescue "N/A"),
      project_unit.user_id,
      (project_unit.user.lead_id rescue "N/A"),
      project_unit.receipts.where(status:"success").sum(&:total_amount),
      project_unit.pending_balance({strict: true}),
      project_unit.ageing
    ]
  end
end
