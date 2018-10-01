module SFDC
  class LeadsPusher < Base
    def self.execute(user)
      if Rails.env.production? || Rails.env.staging?
        begin
          leads_data = [lead_json(user)]
          @leads_cron = SFDC::Base.new
          response = @leads_cron.push("/services/apexrest/Embassy/LeadInfoSellDo", leads_data)
          Rails.logger.info("SFDC::LeadsPusher >>>>> #{response}")
        rescue Exception => e
          AmuraLog.debug("Exception in SFDC::LeadsPusher lead_id: #{user.lead_id.to_s} >>>> #{e.message} \n #{e.backtrace}", "sfdc_pusher.log")
        end
      end
    end

    def self.lead_json(user)
      hash = {
        "api_source" => "sell.do",
        "selldo_lead_id" => user.lead_id,
        "primary_phone" => ("#{Phonelib.parse(user.phone).sanitized.gsub(Phonelib.parse(user.phone).country_code, '')}" rescue ""),
        "primary_email" => user.email,
        "secondary_phone_number" => "",
        "secondary_email" => "",
        "primary_sales_person" => "",
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "medium_name" => "",
        "campaign_id" => "",
        "first_enquiry_received_at" => user.created_at,
        "reengaged_at" => "",
        "first_call_feedback" => "",
        "lead_status" => "Open",
        "lead_sub_status" => "",
        "lead_unqualification_reason" => "",
        "country_code_primary_phone" => (Phonelib.parse(user.phone).country_code rescue ""),
        "min_budget" => "",
        "max_budget" => "",
        "min_possession" => "",
        "max_possession" => "",
        "bed_preferences" => "",
        "site_visit_scheduled" => "",
        "site_visit_scheduled_date" => "",
        "site_visit_status" => "",
        "designation" => "",
        "purpose" => "",
        "lead_lost_reason" => "",
        "Project_Interested" => "Embassy Springs Apartments",
        "LeadSource" => "Web",
        "Sub_Source" => "Website",
        "portal_cp_id" => user.manager_id
      }

      hash
    end
  end
end
