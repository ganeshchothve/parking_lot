require 'spreadsheet'
class BookingDetailMisReportWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, BookingDetailMisReportWorker.get_column_names)
    BookingDetail.each_with_index do |booking_detail, index|
      sheet.insert_row(index+1, BookingDetailMisReportWorker.get_booking_detail_row(booking_detail))
    end
    file_name = "booking_detail_mis-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
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
      "Primary UserKYC id",
      "Erp id",
    ]
  end

  def self.get_project_unit_row(booking_detail)
    project_unit = booking_detail.project_unit
    user = booking_detail.user
    [
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.bedrooms,
      (user.name rescue "N/A"),
      (user.email rescue "N/A"),
      (user.phone rescue "N/A"),
      booking_detail.status,
      booking_detail.primary_user_kyc_id
      booking_detail.erp_id
    ]
  end
end
