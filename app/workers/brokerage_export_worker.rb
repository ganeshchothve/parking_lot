require 'spreadsheet'
class BrokerageExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Walk-ins")
    sheet.insert_row(0, BrokerageExportWorker.get_column_names)
    lead_column_size = BrokerageExportWorker.get_column_names.size rescue 0
    lead_column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold
    Invoice.build_criteria({fltrs: filters}.with_indifferent_access).each_with_index do |invoice, index|
      sheet.insert_row(index+1, BrokerageExportWorker.get_invoice_row(invoice))
    end
    file_name = "invoice-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Walk-ins").deliver
  end

  #code for make excel headers bold
  def title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

  def self.get_column_names
    [
      "Invoice Number",
      "Project Name",
      "Booking Detail",
      "Channel Partner",
      "Invoice Raised Date",
      "Status",
      "Rejection Reason",
      "Brokerage Amount",
      "GST Amount",
      "Deduction",
      "Deduction Status",
      "Adjustments",
      "Approved Brokerage Amount",
      "Invoice Approved Date",
      "Total Amount Paid",
      "Issuing Bank",
      "Issuing Bank Branch",
      "Issued Date",
      "Handover Date",
      "Payment Identifier"
    ]
  end

  def self.get_invoice_row(invoice)
    [
      invoice.number,
      invoice.project_name,
      invoice.booking_detail.try(:name),
      invoice.manager.try(:name),
      invoice.raised_date.try(:strftime, '%d/%m/%Y'),
      invoice.get_status,
      invoice.rejection_reason,
      invoice.amount,
      invoice.gst_amount,
      invoice.incentive_deduction.try(:amount),
      invoice.incentive_deduction.try(:get_status),
      invoice.payment_adjustment.try(:absolute_value).to_f,
      invoice.net_amount,
      invoice.approved_date.try(:strftime, '%d/%m/%Y'),
      "Total Amount Paid",
      invoice.cheque_detail.try(:issuing_bank),
      invoice.cheque_detail.try(:issuing_bank_branch),
      invoice.cheque_detail.try(:issued_date).try(:strftime, '%d/%m/%Y'),
      invoice.cheque_detail.try(:handover_date).try(:strftime, '%d/%m/%Y'),
      invoice.cheque_detail.try(:payment_identifier),
    ]
  end
end
