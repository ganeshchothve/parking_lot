module SFDC
  class ChannelPartnerPusher < Base
    def self.execute(channel_partner)
      if Rails.env.production? || Rails.env.staging?
        begin
          channel_partner_data = []
          channel_partner_data << channel_partner_json(channel_partner)
          if channel_partner_data.any?
            @channel_partner_pusher = SFDC::Base.new
            response = @channel_partner_pusher.push("/services/apexrest/Embassy/CPRegistrationsselldo", channel_partner_data)
            options = {}
            options[:payload] = channel_partner_data unless Rails.env.production?
            AmuraLog.debug("SFDC::ChannelPartnerPusher >>>>> cp_id: #{channel_partner.id.to_s}, SFDC response: #{response}", "sfdc_pusher.log", options)
          end
        rescue Exception => e
          AmuraLog.debug("Exception in SFDC::ChannelPartnerPusher >>>>> cp_id: #{channel_partner.id.to_s} >>>> #{e.message} \n #{e.backtrace}", "sfdc_pusher.log")
        end
      end
    end

    def self.channel_partner_json(channel_partner)
      hash = {
        "cp_id" => channel_partner.id.to_s,
        "title" => channel_partner.title,
        "first_name" => channel_partner.first_name, 
        "last_name" => channel_partner.last_name,
        "street2" => nil,
        "street" => channel_partner.street,
        "street3" => nil,
        "house_number" => channel_partner.house_number.to_s, 
        "district" => nil,
        "city" => channel_partner.city,
        "postal_code" => channel_partner.postal_code,
        "country" => channel_partner.country,
        "region" => nil, #channel_partner.region
        "telephone" => nil,
        "mobile_phone" => channel_partner.mobile_phone.to_s,
        "email" => channel_partner.email, 
        "company_name" =>  channel_partner.company_name,
        "pan_no" => channel_partner.pan_no,
        "gstin_no" => channel_partner.gstin_no, 
        "rera_id" => channel_partner.rera_id.to_s, 
        "bank_name" => channel_partner.bank_name,
        "bank_beneficiary_account_no" => channel_partner.bank_beneficiary_account_no.to_s,
        "bank_account_type" => channel_partner.bank_account_type.to_s,
        "bank_address" =>  channel_partner.bank_address,
        "bank_city" =>  channel_partner.bank_city,
        "bank_postal_Code" => channel_partner.bank_postal_Code,
        "bank_region" => channel_partner.bank_region,
        "bank_country" => channel_partner.bank_country,
        "bank_ifsc_code" => channel_partner.bank_ifsc_code.to_s,
        "bank_phone" => "null"
      }
      hash
    end
  end
end