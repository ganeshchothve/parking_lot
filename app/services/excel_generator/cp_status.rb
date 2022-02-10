module ExcelGenerator::CpStatus

  def  self.cp_status_csv(cp_managers_hash, channel_partners_manager_status_count, channel_partners_status_count)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "CpStatus")
    sheet.insert_row(0, ["Partner Companies Status Wise Counts"])
    sheet.insert_row(1, cp_status_csv_headers)
    column_size = cp_status_csv_headers.size rescue 0
    column_size.times { |x| sheet.row(0).set_format(x, title_format) } #making headers bold 
    column_size.times { |x| sheet.row(1).set_format(x, title_format) }
    index = 1
    cp_managers_hash.each do |cp_id, cp_name|
      sheet.insert_row(index+1, [
        cp_name,
        (channel_partners_manager_status_count[cp_id]["inactive"] || 0),
        (channel_partners_manager_status_count[cp_id]["active"] || 0),
        (channel_partners_manager_status_count[cp_id]["pending"] || 0),
        (channel_partners_manager_status_count[cp_id]["rejected"] || 0),
        (channel_partners_manager_status_count[cp_id]["count"] || 0)
      ])
    end
    total_values = ["Total"]
    %w(inactive active pending rejected total).each do |status|
      total_values << (channel_partners_status_count[status] || 0)
    end
    sheet.merge_cells(0,0,0,5)
    sheet.insert_row(sheet.last_row_index + 1, total_values)
    file_name = "cp_status-#{SecureRandom.hex}.xls"
    spreadsheet = StringIO.new 
    file.write spreadsheet
    spreadsheet
  end

  def self.cp_status_csv_headers
    [
      I18n.t("mongoid.attributes.user/role.cp"),
      "Signed Up Companies",
      "Active Companies",
      "Pending Companies",
      "Rejected Companies",
      I18n.t("global.total"),
    ]
  end

  #code for make excel headers bold
  def self.title_format
    Spreadsheet::Format.new(
      weight: :bold,
    )
  end

end
