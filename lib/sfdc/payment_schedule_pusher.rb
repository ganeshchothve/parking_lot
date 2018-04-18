module SFDC
  class PaymentSchedulePusher < Base
    def self.execute(project_unit)
      if Rails.env.production? || Rails.env.staging?
        begin
          payment_schedule_data = PaymentSchedule.api_json(project_unit)
          if payment_schedule_data.any?
            @payment_schedule_pusher = SFDC::Base.new
            response = @payment_schedule_pusher.push("/services/apexrest/Embassy/PaymentSchedulesInfo", payment_schedule_data)
            Rails.logger.info("SFDC::PaymentSchedulePusher response >>>>> project_unit_id: #{project_unit.id.to_s}, SFDC response: #{response}")
          end
        rescue Exception => e
          Rails.logger.info("Exception in SFDC::PaymentSchedulePusher >>>> #{e.message} \n #{e.backtrace}")
        end
      end
    end
  end #End of class
end #End of module
