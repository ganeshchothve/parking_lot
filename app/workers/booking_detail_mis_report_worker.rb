require 'spreadsheet'
class BookingDetailMisReportWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, BookingDetailMisReportWorker.get_column_names)
    row = 1
    BookingDetail.each_with_index do |booking_detail, index|
      sheet.insert_row(row, BookingDetailMisReportWorker.get_booking_detail_row(booking_detail))
      row = row + 1
      if (booking_detail.try(:booking_detail_scheme).try(:payment_adjustments).try(:count) || 0) > 1
        payment_adjustments = booking_detail.booking_detail_scheme.payment_adjustments
        payment_adjustments = payment_adjustments.drop(1)
        payment_adjustments.each do |pa|
          sheet.insert_row(row,  Array.new(22, "") + [ pa.try(:field), pa.value(booking_detail)])
          row = row + 1
        end
      end

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
      "Blocked on",
      'Ageing',
      "Current Due",
      "Total amount paid",
      "Pending balance",
      "Payment against agreement",
      "Payment against stamp_duty",
      "GST",
      "Registration charges",
      "Stamp duty",
      "Agreement price",
      "All Inclusive price",
      "Scheme name",
      "Scheme status",
      "Negotiation - FEILD",
      "Negotiation - VALUE"
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
      BookingDetail.human_attribute_name("status.#{booking_detail.status}"),
      project_unit.blocked_on.try(:strftime, '%d/%m/%Y'),
      booking_detail.ageing,
      booking_detail.pending_balance({strict: true}),
      booking_detail.total_amount_paid,
      booking_detail.pending_balance,
      booking_detail.payment_against_agreement,
      booking_detail.payment_against_stamp_duty,
      booking_detail.costs.where(key: 'vat_gst').first.try(:value) || "N/A",
      booking_detail.costs.where(key: 'reg_charges').first.try(:value) || "N/A",
      booking_detail.costs.where(key: 'stamp_duty_charges').first.try(:value) || "N/A",
      booking_detail.calculate_agreement_price,
      booking_detail.calculate_all_inclusive_price,
      booking_detail.try(:booking_detail_scheme).try(:derived_from_scheme).try(:name) || "N/A",
      booking_detail.try(:booking_detail_scheme).try(:status) || "N/A",
      booking_detail.try(:booking_detail_scheme).try(:payment_adjustments).try(:first).try(:field),
      booking_detail.try(:booking_detail_scheme).try(:payment_adjustments).try(:first).try(:value, booking_detail)
    ]
  end
end
