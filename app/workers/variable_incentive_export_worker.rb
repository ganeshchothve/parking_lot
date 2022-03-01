require 'spreadsheet'
class VariableIncentiveExportWorker
  include Sidekiq::Worker

  def perform user_id, options={}
    user = User.find(user_id)
    options = options.with_indifferent_access
    get_query = options[:query]
    variable_incentive_schemes = VariableIncentiveScheme.approved.or(get_query)
    vis_details = VariableIncentiveSchemeCalculator.vis_details(variable_incentive_schemes, options)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Variable Incentive Scheme")
    sheet.insert_row(0, VariableIncentiveExportWorker.get_column_names)
    vis_column_size = VariableIncentiveExportWorker.get_column_names.size rescue 0
    vis_column_size.times { |x| sheet.row(0).set_format(x, title_format) }
    vis_details.each_with_index do |vis_detail, index|
      sheet.insert_row(index+1, VariableIncentiveExportWorker.get_incentive_row(vis_detail))
    end
    file_name = "vis_detail-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Variable Incentive Details").deliver
  end

  # code for make excel headers bold
  def title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

  def self.get_column_names
    [
      "Variable Incentive Scheme",
      "Day",
      "Partner / Manager / Added by",
      "Project",
      "Booking",
      "Capped Incentive Amount"
    ]
  end

  def self.get_incentive_row(vis_detail)
    [
      vis_detail[:scheme_name],
      vis_detail[:day],
      vis_detail[:manager_name],
      vis_detail[:project_name],
      vis_detail[:booking_detail_name],
      (vis_detail[:capped_incentive] rescue 0.0)
    ]
  end
end