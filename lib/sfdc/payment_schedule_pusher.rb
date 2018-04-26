module SFDC
  class PaymentSchedulePusher < Base
    def self.execute(project_unit)
      if Rails.env.production? || Rails.env.staging?
        begin
          payment_schedule_data = PaymentSchedule.api_json(project_unit)
          if payment_schedule_data.any?
            @payment_schedule_pusher = SFDC::Base.new
            response = @payment_schedule_pusher.push("/services/apexrest/Embassy/PaymentSchedulesInfo", payment_schedule_data)
            options = {}
            options[:payload] = payment_schedule_data unless Rails.env.production?
            AmuraLog.debug("SFDC::PaymentSchedulePusher response >>>>> project_unit_id: #{project_unit.id.to_s}, SFDC response: #{response}", "sfdc_pusher.log", options)
          end
        rescue Exception => e
          AmuraLog.debug("Exception in SFDC::PaymentSchedulePusher project_unit_id: #{project_unit.id.to_s} >>>> #{e.message} \n #{e.backtrace}", "sfdc_pusher.log")
        end
      end
    end
  end #End of class
end #End of module
