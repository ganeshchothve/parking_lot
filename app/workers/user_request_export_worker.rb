require 'spreadsheet'
class UserRequestExportWorker
  include Sidekiq::Worker

  def perform(user_id, filters = nil)
    filters = JSON.parse(filters) if filters.present? && filters.is_a?(String)
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: 'Cancellation Report')
    sheet.insert_row(0, UserRequestExportWorker.get_column_names)
    user_requests = UserRequest.build_criteria({ fltrs: filters }.with_indifferent_access)
    user_requests = user_requests.where(UserRequest.user_based_scope(user))
    user_requests.each_with_index do |user_request, index|
      sheet.insert_row(index + 1, UserRequestExportWorker.get_user_request_row(user_request))
    end
    file_name = "cancellation-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, 'Cancellation Report').deliver
  end

  def self.get_column_names
    [
      'Request ID (Used for Bulk Update)',
      'Customer ID',
      'SellDo Lead ID',
      'User name',
      'Request Date',
      'Type',
      'Unit ID (Used for VLOOKUP)',
      'Status',
      'Processed On',
      'Resolved by'
    ]
  end

  def self.get_user_request_row(user_request)
    [
      user_request.id.to_s,
      user_request.user.id.to_s,
      (user_request.user.lead_id.presence || ''),
      user_request.user.name,
      user_request.created_at.strftime('%Y-%m-%d T %l:%M:%S'),
      user_request._type.split('::')[1],
      user_request.requestable.name,
      I18n.t("mongoid.attributes.user_request/status.#{user_request.status}"),
      user_request.resolved_at.try(:strftime, '%Y-%m-%d T %l:%M:%S') || '-',
      user_request.resolved_by.try(:name) || '-'
    ]
  end
end
