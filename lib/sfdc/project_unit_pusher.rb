module SFDC
  class ProjectUnitPusher < Base
    def self.execute(project_unit, options={})
      if Rails.env.production? || Rails.env.staging?
        begin
          project_unit_data = []
          project_unit_data << project_unit_json(project_unit, options)
          if project_unit_data.any?
            @project_unit_pusher = SFDC::Base.new
            response = @project_unit_pusher.push("/services/apexrest/Embassy/LeadInfo", project_unit_data)
            options = {}
            options[:payload] = project_unit_data unless Rails.env.production?
            AmuraLog.debug("SFDC::ProjectUnitPusher response >>>>> project_unit_id: #{project_unit.id.to_s}, SFDC response: #{response}", "sfdc_pusher.log", options)
          end
        rescue Exception => e
          AmuraLog.debug("Exception in SFDC::ProjectUnitPusher >>>>> project_unit_id: #{project_unit.id.to_s} >>>> #{e.message} \n #{e.backtrace}", "sfdc_pusher.log")
        end
      end
    end

    def self.project_unit_json(project_unit, options={})
      # If user has cancelled the booking, then that project may belong to other user, so need to depend on booking_detail's user_id
      if options[:cancellation_request]
        user = User.find(options[:user_id])
        user_kyc = UserKyc.find(options[:primary_user_kyc_id])
      else
        user = project_unit.user
        user_kyc = project_unit.primary_user_kyc
      end
      unit_sfdc_id = project_unit.sfdc_id
      opp_id = user.lead_id.to_s + unit_sfdc_id.to_s

      hash = {
        "api_source" => "portal",
        "opp_id" => opp_id,
        "selldo_lead_id" => user.lead_id,
        "unit_sfdc_id" => project_unit.sfdc_id,
        "booking_stage" => options[:cancellation_request] ? 'Closed Lost' : sfdc_stage_mapping(project_unit.status),
        "booking_date" => sfdc_date_format(Date.today),
        "birthdate" => sfdc_date_format(project_unit.primary_user_kyc.dob),
        "pan_card_number" => project_unit.primary_user_kyc.pan_number,
        "nri" => user_kyc.nri ? "NRI" : "Indian",
        "house_number" => user_kyc.house_number,
        "street" => user_kyc.street,
        "city" => user_kyc.city,
        "state" => user_kyc.state,
        "country" => user_kyc.country,
        "zip" => user_kyc.postal_code,
        "aadhar_number" => user_kyc.aadhaar,
        "salutation" => user_kyc.salutation,
        "company_name" => user_kyc.company_name
      }
      hash
    end

    def self.sfdc_stage_mapping(status)
      case status
      when "blocked"
        "Blocked"
      when "booked_confirmed"
        "Booking"
      end
    end
  end
end
