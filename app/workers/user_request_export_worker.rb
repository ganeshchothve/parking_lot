require 'spreadsheet'
class UserRequestExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Cancellation Report")
    sheet.insert_row(0, UserRequestExportWorker.get_column_names)
    user_requests = UserRequest.build_criteria({fltrs: filters}.with_indifferent_access)
    user_requests = user_requests.where(UserRequest.user_based_scope(user))
    user_requests.each_with_index do |user_request, index|
      sheet.insert_row(index+1, UserRequestExportWorker.get_user_request_row(user_request))
    end
    file_name = "cancellation-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Cancellation Report").deliver
  end

  def self.get_column_names
    [
      "Request Date",
      "Status",
      "Unit ID (Used for VLOOKUP)",
      "Unit Name",
      "Amount Paid",
      "User ID (Used for VLOOKUP)",
      "Client Name",
      "Client Phone",
      "Client Email",
      "Comments",
    ]
  end

  def self.get_user_request_row(user_request)
    [
      user_request.created_at,
      user_request.status,
      user_request.project_unit_id,
      user_request.project_unit.name,
      user_request.project_unit.receipts.where(status:"success").sum(&:total_amount),
      user_request.user_id,
      user_request.user.name,
      user_request.user.phone,
      user_request.user.email,
      user_request.notes.collect{|note|  note.note + " - " + note.creator.name}.join("\n")
    ]
  end
end
