module ChannelPartnerImport
  def self.perform(filepath)
    count = 0
    CSV.foreach(filepath, row_sep: :auto) do |row|
      unless count == 0
        company_name = row[0].strip
        first_name = row[1].strip.split(" ").first
        last_name = row[1].strip.split(" ").last
        email = row[2].strip
        phone = row[3].strip

        channel_partner = ChannelPartner.new
        channel_partner.company_name = company_name
        channel_partner.first_name = first_name
        channel_partner.last_name = last_name
        channel_partner.email = email
        channel_partner.phone = Phonelib.parse(phone).international
        channel_partner.rera_id = channel_partner.phone

        if channel_partner.valid?
          puts "Saved #{channel_partner.name}"
        else
          puts "Error in saving #{channel_partner.name} : #{channel_partner.errors.full_messages}"
        end
      end
      count += 1
    end
  end
end
