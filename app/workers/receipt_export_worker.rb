require 'spreadsheet'
class ReceiptExportWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Receipts")
    sheet.insert_row(0, ReceiptExportWorker.get_column_names)
    Receipt.where(Receipt.user_based_scope(user)).each_with_index do |receipt, index|
      sheet.insert_row(index+1, ReceiptExportWorker.get_receipt_row(receipt))
    end
    file_name = "receipt-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Payments").deliver
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
      "Project Unit",
      "Applied Discount Rate",
      "Base Rate",
      "Land Rate",
      "Floor Rise",
      "PLC",
      "Clubhouse Amenities Price",
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
      Receipt.available_payment_modes.select{|x| x[:id] == receipt.payment_mode}.first[:text],
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
      receipt.user_id,
      receipt.user.manager_id.present? ? receipt.user.manager.name : "N/A",
      receipt.user.manager_id.present? ? User.available_roles(receipt.user.booking_portal_client).find{|x| x[:id] == receipt.user.manager.role}[:text] : "Direct",
      receipt.project_unit_id.present? ? receipt.project_unit.name : "N/A",
      (receipt.project_unit.applied_discount_rate rescue "N/A"),
      (receipt.project_unit.base_rate rescue "N/A"),
      (receipt.project_unit.land_rate rescue "N/A"),
      (receipt.project_unit.floor_rise rescue "N/A"),
      (receipt.project_unit.premium_location_charges rescue "N/A"),
      (receipt.project_unit.clubhouse_amenities_price rescue "N/A"),
      receipt.creator.name,
      receipt.created_at,
      (receipt.project_unit.receipts.where(status:"success").sum(&:total_amount) rescue "0"),
      receipt.comments
    ]
  end
end
