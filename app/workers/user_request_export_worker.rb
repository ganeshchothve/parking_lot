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
      "Sell.do lead id",
      "User name",
      "Request Date",
      "Type",
      "Status",
      "Unit ID (Used for VLOOKUP)",
      "Resolved by",
    ]
  end

  def self.get_user_request_row(user_request)
    [
      user_request.user.lead_id,
      user_request.user.name,
      user_request.created_at,
      user_request._type,
      user_request.status,
      user_request.project_unit.name,
      user_request.resolved_by.name
    ]
  end
end
