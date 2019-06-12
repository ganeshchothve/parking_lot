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
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Units").deliver
  end

  def self.get_column_names
    [
      "Erp id",
      "Unit Name",
      "Unit Type",
      "Type of Apartment",
      "User Name",
      "User Email",
      "User Phone",
      "Status",
      'Ageing',
      "Current Due",
      "Total amount paid",
      "Pending balance",
    ]
  end

  def self.get_booking_detail_row(booking_detail)
    project_unit = booking_detail.project_unit
    user = booking_detail.user
    [
      project_unit.erp_id,
      project_unit.name,
      project_unit.unit_configuration_name,
      project_unit.bedrooms,
      booking_detail.user_name || 'N/A',
      booking_detail.user_email || "N/A",
      booking_detail.user_phone || "N/A",
      booking_detail.status,
      booking_detail.ageing,
      booking_detail.pending_balance({strict: true}),
      booking_detail.total_amount_paid,
      booking_detail.pending_balance,
    ]
  end
end
