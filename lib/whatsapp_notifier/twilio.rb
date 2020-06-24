#
# Class WhatsappNotifier selects whatsapp vendor and sends the whatsapp message
#
# @author Dnyaneshwar Burgute <dnyaneshwar.burgute@sell.do>
#
require 'net/http'
module WhatsappNotifier
  class Twilio
    def initialize(whatsapp)
      @params = {}
      @params[:from] = "whatsapp:#{whatsapp.from}"
      @params[:to] = "whatsapp:#{whatsapp.to}"
      @params[:message] = whatsapp.content
      @params[:username] = whatsapp.booking_portal_client.whatsapp_api_key
      @params[:pass] = whatsapp.booking_portal_client.whatsapp_api_secret
      @params[:media_url] = whatsapp.media_url
      @params[:client_id] = whatsapp.booking_portal_client_id.to_s
    end

    # Sends message on behalf of client
    def send
      client = ::Twilio::REST::Client.new(@params[:username], @params[:pass])
      hash = {
        from: @params[:from],
        to: @params[:to],
        body: @params[:message],
      }
      hash[:media_url] = @params[:media_url].to_s if @params[:media_url].present?
      response = client.api.account.messages.create(hash)
      { status: response.status, message_sid: response.sid, api_version: response.api_version }
    end
  end
end
