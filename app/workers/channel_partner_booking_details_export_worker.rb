require 'spreadsheet'
class ChannelPartnerBookingDetailsExportWorker
  include Sidekiq::Worker

  def perform emails
    file = Spreadsheet::Workbook.new
    sheet = file.create_worksheet(name: "ChannelPartners")
    sheet.insert_row(0, ChannelPartnerBookingDetailsExportWorker.get_column_names)
    ChannelPartner.all.each_with_index do |channel_partner, index|
      sheet.insert_row(index+1, ChannelPartnerBookingDetailsExportWorker.get_channel_partner_row(channel_partner))
    end
    file_name = "channel-partner-bookin-#{SecureRandom.hex}.xls"
    file.write("#{Rails.root}/#{file_name}")
    ExportMailer.notify(file_name, emails, "Channel Partners").deliver
  end

  def self.get_column_names
    [
      "Name",
      "Leads",
      "Confirmed customers",
      "Bookings",
      "Blocked"
    ]
  end

  def self.get_channel_partner_row(channel_partner)
    [
      channel_partner.name,
      User.where(channel_partner_id: channel_partner.id, confirmation_token: nil).count,
      User.where(channel_partner_id: channel_partner.id, confirmation_token: {"$exists": true}).count,
      BookingDetail.where(channel_partner_id: channel_partner.id, status: "booked").count,
      BookingDetail.where(channel_partner_id: channel_partner.id, status: "blocked").count,
    ]
  end
end
