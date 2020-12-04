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
      DailyReportMailer.payments_report(file_name, receipts.count, filters[:project_id]).deliver
    end
  end

  def self.get_column_names
    [
      "ID (Used for Bulk Upload)",
      "Customer ID",
      "SellDo Lead ID",
      "Receipt ID",
      "Order ID",
      "Token Number",
      "Payment Mode",
      "Issued Date",
      "Issuing Bank",
      "Issuing Bank Branch",
      "Payment Identifier",
      "Payment Type",
      "Tracking ID",
      "Total Amount",
      "Status",
      "Status Message",
      "Payment Gateway",
      "Client Name",
      "Email",
      "Phone",
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
      receipt.id.to_s,
      receipt.user.id.to_s,
      (receipt.user.lead_id.presence || ''),
      receipt.receipt_id,
      receipt.order_id,
      receipt.get_token_number,
      Receipt.human_attribute_name("payment_mode.#{receipt.payment_mode}"),
      receipt.issued_date,
      receipt.issuing_bank,
      receipt.issuing_bank_branch,
      receipt.payment_identifier,
      Receipt.human_attribute_name("payment_type.#{receipt.payment_type}"),
      receipt.tracking_id,
      receipt.total_amount,
      Receipt.human_attribute_name("status.#{receipt.status}"),
      receipt.status_message,
      Client.human_attribute_name("payment_gateway.#{receipt.payment_gateway}"),
      receipt.user.name,
      receipt.user.try(:email) || "-",
      receipt.user.try(:phone) || "-",
      receipt.user.lead_id.to_s,
      receipt.user.manager_name || "N/A",
      User.human_attribute_name("role.#{receipt.user.manager_role || 'direct'}"),
      receipt.booking_detail_name || "N/A",
      receipt.creator.name,
      receipt.created_at,
      (receipt.booking_detail ? receipt.booking_detail.receipts.success.sum(&:total_amount) : "0"),
      receipt.comments
    ]
  end
end
