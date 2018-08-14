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
            options = {}
            options[:payload] = receipts_data unless Rails.env.production?
            AmuraLog.debug("SFDC::ReceiptsPusher >>>>> receipt_id: #{receipt.id.to_s}, SFDC response: #{response}", "sfdc_pusher.log", options)
          end
        rescue Exception => e
          AmuraLog.debug("Exception in SFDC::ReceiptsPusher >>>>> receipt_id: #{receipt.id.to_s} >>>> #{e.message} \n #{e.backtrace}", "sfdc_pusher.log")
        end
      end
    end

    def self.receipt_json(receipt)
      project_unit = receipt.project_unit
      unit_erp_id = project_unit.try(:erp_id)
      lead_id = receipt.user.lead_id
      opp_id = lead_id.to_s + unit_erp_id.to_s
      hash = {
        "opp_id" => opp_id,
        "receipt_selldo_id" => receipt.id.to_s,
        "selldo_lead_id" => lead_id,
        "unit_sfdc_id" => unit_erp_id,
        "primary_email" => receipt.user.email,
        "receipt_date" => sfdc_date_format(receipt.created_at),
        "payment_amount" => receipt.total_amount,
        "mode_of_transfer" => receipt.payment_mode,
        "instrument_no" => receipt.payment_identifier.to_s,
        "instrument_date" => receipt.issued_date ? sfdc_date_format(receipt.issued_date) : sfdc_date_format(receipt.created_at),
        "instrument_received_date" => receipt.issued_date ? sfdc_date_format(receipt.issued_date) : sfdc_date_format(receipt.created_at),
        "bank_name" => receipt.issuing_bank,
        "branch_name" => receipt.issuing_bank_branch,
        "payment_type" => (project_unit.status == 'blocked' ? 'Advance' : 'Booking'),
        "portal_receipt_id" => receipt.receipt_id
      }
      hash
    end
  end
end
