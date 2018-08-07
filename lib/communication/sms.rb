require 'net/http'
require 'rexml/document'
module Communication
  module Sms
    class Smsjust
      def self.execute sms_id
        sms = ::Sms.find sms_id
        client = sms.booking_portal_client
        params = {}
        params[:senderid] = client.sms_mask
        params[:dest_mobileno] = sms.recipient.phone
        params[:message] = sms.body
        params[:username] = client.sms_provider_username
        params[:pass] = client.sms_provider_password
        params[:response] = "Y"

        uri = URI("http://www.smsjust.com/blank/sms/user/urlsms.php")
        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri).body

        if response.starts_with?("ES")
          return {status:"fail", remote_id: response}
        else
          return {status:"success", remote_id: response}
        end
      end
    end
  end
end
