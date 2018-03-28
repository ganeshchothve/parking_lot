module SFDC
  class ProjectUnitPusher < Base
    def self.execute(project_unit)
      if Rails.env.production?
        client_id = project_unit.id
        begin
          project_unit_data = []
          project_unit_data << receipt_json(project_unit)
          if project_unit_data.any?
           @project_unit_pusher = SFDC::Base.new
           response = @project_unit_pusher.push("/services/apexrest/Embassy/LeadInfo", project_unit_data)
          end
        rescue Exception => e
          # Rails.logger.info "---------------------------Exception-----------------------------------"
          options = { error_class: e.class, error_message: ('Exception in SFDC ReceiptsCron: ' + e.message), parameters: { client_id: client_id } }
          # Rails.logger.info('error', options)
          # Rails.logger.info("Exception in SFDC::ReceiptsCron >>>> #{e.message} \n #{e.backtrace}", "sfdc_cron.log")
        end
      end
    end

    def self.project_unit_json(project_unit)
      hash = {
        "receipt_selldo_id" => receipt.id.to_s,
        "selldo_lead_id" => receipt.project_unit.user.lead_id,
        "primary_email" => receipt.user.email,
        "receipt_date" => sfdc_date_format(receipt.created_at),
        "payment_amount" => receipt.total_amount,
        "mode_of_transfer" => receipt.payment_mode,
        "instrument_no" => receipt.payment_identifier.to_s,
        "instrument_date" => receipt.issued_date ? sfdc_date_format(Date.parse(receipt.issued_date)) : nil,
        "bank_name" => receipt.issuing_bank,
        "branch_name" => receipt.issuing_bank_branch,
          "selldo_lead_id": user.lead_id,
          "booking_stage": "blocked", 
          "booking_date": "2018-03-26",
          "birthdate": "1980-10-16",
          "pan_card_number": "ATZQWE3540P",
          "unit_sfdc_id": "a0K0l000000jhlk"

      }
      hash
    end
  end
end
