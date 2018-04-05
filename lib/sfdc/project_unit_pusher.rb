module SFDC
  class ProjectUnitPusher < Base
    def self.execute(project_unit)
      if Rails.env.production? || Rails.env.staging?
        begin
          project_unit_data = []
          project_unit_data << project_unit_json(project_unit)
          if project_unit_data.any?
            @project_unit_pusher = SFDC::Base.new
            response = @project_unit_pusher.push("/services/apexrest/Embassy/LeadInfo", project_unit_data)
            Rails.logger.info("SFDC::ProjectUnitPusher >>>>> project_unit_id: #{project_unit.id.to_s}, SFDC response: #{response}")
          end
        rescue Exception => e
          Rails.logger.info("Exception in SFDC::ProjectUnitPusher >>>> #{e.message} \n #{e.backtrace}")
        end
      end
    end

    def self.project_unit_json(project_unit)
      user = project_unit.user
      user_kyc = project_unit.primary_user_kyc
      hash = {
        "selldo_lead_id": user.lead_id,
        "unit_sfdc_id": project_unit.sfdc_id,
        "booking_stage": sfdc_stage_mapping(project_unit.status),
        "booking_date": sfdc_date_format(project_unit.blocked_on),
        "birthdate": sfdc_date_format(project_unit.primary_user_kyc.dob),
        "pan_card_number": project_unit.primary_user_kyc.pan_number,
        "nri": user_kyc.nri ? "NRI" : "Indian",
        "street" => user_kyc.street,
        "city" => user_kyc.city,
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
        "blocked"
      when "booked_confirmed"
        "booking"
      end
    end
  end
end
