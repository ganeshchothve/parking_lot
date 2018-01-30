require 'spreadsheet'
class ReceiptExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ReceiptExportWorker.get_column_names)
    Receipt.all.each_with_index do |receipt, index|
      sheet.insert_row(index+1, ReceiptExportWorker.get_receipt_row(receipt))
    end
    file_name = "receipt-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify file_name, emails, "Payments"
  end

  def self.get_column_names
    [
      "Receipt ID",
      "Order ID",
      "Payment Mode",
      "Issued Date",
      "Issuing Bank",
      "Issuing Bank Branch",
      "Payment IDentifier",
      "Tracking ID",
      "Total Amount",
      "Status",
      "Status Message",
      "Payment Type",
      "Payment Gateway",
      "Customer",
      "User ID (Used for VLOOKUP)",
      "Project Unit",
      "Created By"
    ]
  end

  def self.get_receipt_row(receipt)
    [
      receipt.receipt_id,
      receipt.order_id,
      Receipt.available_payment_modes.select{|x| x[:id] == receipt.payment_mode}.first[:text],
      receipt.issued_date,
      receipt.issuing_bank,
      receipt.issuing_bank_branch,
      receipt.payment_identifier,
      receipt.tracking_id,
      receipt.total_amount,
      Receipt.available_statuses.select{|x| x[:id] == receipt.status}.first[:text],
      receipt.status_message,
      Receipt.available_payment_types.select{|x| x[:id] == receipt.payment_type}.first[:text],
      receipt.payment_gateway,
      receipt.user.name,
      receipt.user_id,
      receipt.project_unit_id.present? ? receipt.project_unit.name : "",
      receipt.creator.name
    ]
  end
end
