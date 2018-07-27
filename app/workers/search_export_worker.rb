require 'spreadsheet'
class SearchExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "Searches Report")
    sheet.insert_row(0, SearchExportWorker.get_column_names)
    Search.all.each_with_index do |search, index|
      sheet.insert_row(index+1, SearchExportWorker.get_search_row(search))
    end
    file_name = "cancellation-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, emails, "Cancellation Report").deliver
  end

  def self.get_column_names
    [

    ]
  end

  def self.get_search_row(search)
    [

    ]
  end
end
