require 'spreadsheet'
class ReceiptExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil, options={}
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id) if user_id
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ReceiptExportWorker.get_column_names)
    receipts = Receipt.build_criteria({fltrs: filters}.with_indifferent_access)
    receipts = receipts.where(Receipt.user_based_scope(user)) if user_id
    receipts.each_with_index do |receipt, index|
      sheet.insert_row(index+1, ReceiptExportWorker.get_receipt_row(receipt))
    end
    if user_id
      file_name = "receipt-#{SecureRandom.hex}.xls"
      file.write("#{Rails.root}/exports/#{file_name}")
      ExportMailer.notify(file_name, user.email, "Payments").deliver
    else options[:daily_report]
      file_name = "receipt-#{DateTime.current.in_time_zone('Mumbai').strftime('%F-%T')}.xls"
      file.write("#{Rails.root}/exports/#{file_name}")
      DailyReportMailer.payments_report(file_name, receipts.count).deliver
    end
  end

  def self.get_column_names
    [
      "Receipt ID",
      "Order ID",
      "Payment Mode",
      "Issued Date",
      "Issuing Bank",
      "Issuing Bank Branch",
      "Payment Identifier",
      "Tracking ID",
      "Total Amount",
      "Status",
      "Status Message",
      "Payment Gateway",
      "Client Name",
      "User ID (Used for VLOOKUP)",
      "Manager Name",
      "Manager Role (Source)",
      "Booking",
      "Created By",
      "Receipt Date",
      "Amount Received",
      "Comments"
    ]
  end

  def self.get_receipt_row(receipt)
    [
      receipt.receipt_id,
      receipt.order_id,
      I18n.t("receipts.payment_mode.#{receipt.payment_mode}"),
      receipt.issued_date,
      receipt.issuing_bank,
      receipt.issuing_bank_branch,
      receipt.payment_identifier,
      receipt.tracking_id,
      receipt.total_amount,
      receipt.status.titleize,
      receipt.status_message,
      receipt.payment_gateway,
      receipt.user.name,
      receipt.user.lead_id.to_s,
      receipt.user.manager_name || "N/A",
      receipt.user.manager_id.present? ? I18n.t("users.role.#{receipt.user.manager.role}"): "Direct",
      receipt.booking_detail_name || "N/A",
      receipt.creator.name,
      receipt.created_at,
      (receipt.booking_detail ? receipt.booking_detail.receipts.success.sum(&:total_amount) : "0"),
      receipt.comments
    ]
  end
end
