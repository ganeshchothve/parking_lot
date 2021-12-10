require 'spreadsheet'
class ChannelPartnerExportWorker
  include Sidekiq::Worker

  def perform user_id, filters=nil
    if filters.present? && filters.is_a?(String)
      filters =  JSON.parse(filters)
    end
    user = User.find(user_id)
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "ChannelPartners")
    sheet.insert_row(0, ChannelPartnerExportWorker.get_column_names)
    ChannelPartner.build_criteria({fltrs: filters}.with_indifferent_access).each_with_index do |channel_partner, index|
      sheet.insert_row(index+1, ChannelPartnerExportWorker.get_channel_partner_row(channel_partner))
    end
    file_name = "channel-partner-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/exports/#{file_name}")
    ExportMailer.notify(file_name, user.email, "Channel Partners").deliver
  end

  def self.get_column_names
    [
      "ID (Used for Bulk Upload)",
      "Company Name",
      "Email",
      "Phone",
      "RERA ID",
      "Associated User",
      "Associated User ID (used for VLOOKUP)",
      "Status"
    ]
  end

  def self.get_channel_partner_row(channel_partner)
    user = channel_partner.users&.cp_owner&.first
    [
      channel_partner.id.to_s,
      channel_partner.company_name,
      user&.email,
      user&.phone,
      channel_partner.rera_id,
      user&.name,
      user&.id&.to_s,
      ChannelPartner.human_attribute_name("status.#{channel_partner.status}")
    ]
  end
end
