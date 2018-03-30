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
          end
        rescue Exception => e
          Rails.logger.info "---------------------------Exception-----------------------------------"
          Rails.logger.info("Exception in SFDC::ProjectUnitPusher >>>> #{e.message} \n #{e.backtrace}")
        end
      end
    end

    def self.project_unit_json(project_unit)
      hash = {
        "receipt_selldo_id" => receipt.id.to_s,
        "selldo_lead_id" => receipt.project_unit.user.lead_id,
        "street" => project_unit.primary_user_kyc.street,
        "city" =>  project_unit.primary_user_kyc.city,
        "country" => project_unit.primary_user_kyc.country,
        "zip" =>  project_unit.primary_user_kyc.zip,
        "primary_email" => receipt.user.email,
        "receipt_date" => sfdc_date_format(receipt.created_at),
        "payment_amount" => receipt.total_amount,
        "mode_of_transfer" => receipt.payment_mode,
        "instrument_no" => receipt.payment_identifier.to_s,
        "instrument_date" => receipt.issued_date ? sfdc_date_format(Date.parse(receipt.issued_date)) : nil,
        "bank_name" => receipt.issuing_bank,
        "branch_name" => receipt.issuing_bank_branch,
        "selldo_lead_id": user.lead_id,
        "booking_stage": project_unit.status,
        "booking_date": project_unit.blocked_on,
        "birthdate": project_unit.primary_user_kyc.dob,
        "pan_card_number": project_unit.primary_user_kyc.pan_number,
        "unit_sfdc_id": project_unit.sfdc_id
      }
      hash
    end
  end
end
