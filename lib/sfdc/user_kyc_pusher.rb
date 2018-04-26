module SFDC
  class UserKycPusher < Base
    def self.execute(user_kyc)
      if Rails.env.production? || Rails.env.staging?
        begin
          kyc_data = user_kyc.api_json
          if kyc_data.any?
            @payment_schedule_pusher = SFDC::Base.new
            response = @payment_schedule_pusher.push("/services/apexrest/Embassy/PersonAccountInfo", kyc_data)
            options = {}
            options[:payload] = kyc_data unless Rails.env.production?
            AmuraLog.debug("SFDC::UserKycPusher response >>>>> user_kyc_id: #{user_kyc.id.to_s}, SFDC response: #{response}", "sfdc_pusher.log", options)
          end
        rescue Exception => e
          AmuraLog.debug("Exception in SFDC::UserKycPusher >>>>> user_kyc_id: #{user_kyc.id.to_s} >>>> #{e.message} \n #{e.backtrace}", "sfdc_pusher.log")
        end
      end
    end
  end #End of class
end #End of module
