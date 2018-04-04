module SFDC
  class ReceiptsPusher < Base
    def self.execute(receipt)
      if Rails.env.production? || Rails.env.staging?
        begin
          receipts_data = []
          receipts_data << receipt_json(receipt)
          if receipts_data.any?
            @receipts_pusher = SFDC::Base.new
            response = @receipts_pusher.push("/services/apexrest/Embassy/receiptsInfo", receipts_data)
            Rails.logger.info("SFDC::ReceiptsPusher >>>>> receipt_id: #{receipt.id.to_s}, SFDC response: #{response}")
          end
        rescue Exception => e
          Rails.logger.info("Exception in SFDC::ReceiptsPusher >>>> #{e.message} \n #{e.backtrace}")
        end
      end
    end

    def self.receipt_json(receipt)
      hash = {
        "receipt_selldo_id" => receipt.id.to_s,
        "selldo_lead_id" => receipt.project_unit.user.lead_id,
        "primary_email" => receipt.user.email,
        "receipt_date" => sfdc_date_format(receipt.created_at),
        "payment_amount" => receipt.total_amount,
        "mode_of_transfer" => receipt.payment_mode,
        "instrument_no" => receipt.payment_identifier.to_s,
        "instrument_date" => receipt.issued_date ? sfdc_date_format(Date.parse(receipt.issued_date)) : sfdc_date_format(receipt.created_at),
        "bank_name" => receipt.issuing_bank,
        "branch_name" => receipt.issuing_bank_branch
      }
      hash
    end
  end
end