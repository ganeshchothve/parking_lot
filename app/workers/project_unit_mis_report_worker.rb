require 'spreadsheet'
class ProjectUnitMisReportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ProjectUnitMisReportWorker.get_column_names)
    ProjectUnit.in(status: ["blocked","booked_tentative","booked_confirmed"]).each_with_index do |project_unit, index|
      sheet.insert_row(index+1, ProjectUnitMisReportWorker.get_project_unit_row(project_unit)) 
    end
    file_name = "project_unit_mis-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    MisReportMailer.notify(file_name, emails, "Units").deliver
  end

  def self.get_column_names
    [
      "Unit Name",
      "Unit Type",
      "Type of Apartment",
      "User Name",
      "User Email",
      "Status",
      "Saleable",
      "Carpet",
      "Base Rate",
      "Floor Rise",
      "PLC",
      "Applied Discount Rate",
      "Effective Price",
      "Land Rate",
      "Construction Rate",
      "Land Price",
      "Construction Price",
      "GST on agreement Price",
      "Agreement price",
      "Water/Electricity/Power Backup",
      "City infrastructure charges",
      "Advance Maintenance charges",
      "Corpus Fund",
      "GST on additional charges",
      "Club house & amenities Charges",
      "Sub total",
      "All inclusive price",
      "Current Due",
      "99%",
      "TDS amount",
      "Total amount paid",
      "Pending balance",
      "Unit SFDC ID",
      "Available for",
      "Blocked on",
      "Auto Release On",
      "Lead Source",
      "Channel Parter",
      "Ageing"
    ]
  end

  def self.get_project_unit_row(project_unit)
    [
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.bedrooms,
      (project_unit.user.name rescue "N/A"),
      (project_unit.user.email rescue "N/A"),
      project_unit.status,
      project_unit.saleable,
      project_unit.carpet,
      project_unit.base_rate,
      project_unit.floor_rise,
      project_unit.premium_location_charges,
      project_unit.applied_discount_rate,
      project_unit.effective_price,
      project_unit.land_rate,
      project_unit.construction_rate,
      project_unit.land_price,
      project_unit.construction_price,
      project_unit.gst_on_agreement_price,
      project_unit.agreement_price,
      project_unit.wep_price.round(2),
      project_unit.city_infrastructure_fund.round(2),
      project_unit.advance_maintenance_charges.round(2),
      project_unit.corpus_fund.round(2),
      project_unit.gst_on_additional_charges,
      project_unit.clubhouse_amenities_price,
      project_unit.sub_total,
      project_unit.all_inclusive_price,
      project_unit.pending_balance({strict: true}),
      project_unit.ninetynine_percent,
      project_unit.tds_amount,
      project_unit.total_amount_paid,
      project_unit.pending_balance,
      project_unit.sfdc_id,
      project_unit.available_for,
      project_unit.blocked_on,
      project_unit.auto_release_on,
      project_unit.lead_source,
      project_unit.channel_partner_name,
      project_unit.ageing
    ]
  end
end
