require 'spreadsheet'
class UserRequestExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Cancellation Report")
    sheet.insert_row(0, UserRequestExportWorker.get_column_names)
    UserRequest.where(request_type:"cancellation").all.each_with_index do |user_request, index|
      sheet.insert_row(index+1, UserRequestExportWorker.get_user_request_row(user_request))
    end
    file_name = "cancellation-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, emails, "Cancellation Report").deliver
  end

  def self.get_column_names
    [
      "Request Date",
      "Status",
      "Unit ID (Used for VLOOKUP)",
      "Unit Name",
      "Blocking Date",
      "Amount Paid",
      "User ID (Used for VLOOKUP)",
      "Client Name",
      "Client Comments",
      "CRM Comments"
    ]
  end

  def self.get_user_request_row(user_request)
    [
      user_request.created_at,
      user_request.status,
      user_request.project_unit_id,
      user_request.project_unit.name,
      user_request.project_unit.blocking_date,
      user_request.project_unit.receipts.where(status:"success").sum(&:total_amount),
      user_request.user_id,
      user_request.user.name,
      user_request.comments,
      "N/A"
    ]
  end
end
