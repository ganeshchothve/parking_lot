require 'net/http'
require 'rexml/document'
module Communication
  module Sms

    # Pinnacle sms Gateway
    class SmsJustWorker
      include Sidekiq::Worker

      def perform sms_id
        sms = ::Sms.find sms_id
        client = sms.booking_portal_client
        template = sms.sms_template
        params = {}
        params[:senderid] = client.sms_mask
        params[:username] = client.sms_provider_username
        params[:password] = client.sms_provider_password
        params[:response] = "Y"

        #sms.variable_list.each do |v|
        #  params["F#{v[:id]}".to_sym] = v[:value]
        #end
        #
        if client.sms_provider_telemarketer_id.present?
          params[:mtype]         = 'TXT'
          params[:subdatatype]   = 'M'
          params[:tmid]          = client.sms_provider_telemarketer_id
          params[:dltentityid]   = client.sms_provider_dlt_entity_id
          params[:dlttempid]     = template.dlt_temp_id
          params[:dlttagid]      = template.dlt_tag_id
          params[:msgdata]       = { data: sms.to.map { |phone| {mobile: phone, message: sms.body} } }.to_json
          uri                    = URI("http://www.smsjust.com/sms/user/urlsms_json.php")
          response               = Net::HTTP.post_form(uri, params)
          response               = JSON.parse(response.body)
        else
          params[:pass]          = client.sms_provider_password
          params[:dest_mobileno] = sms.to.join(",")
          params[:message]       = sms.body
          uri                    = URI("http://www.smsjust.com/blank/sms/user/urlsms.php")
          uri.query              = URI.encode_www_form(params)
          response               = Net::HTTP.get_response(uri).body
        end

        attrs = { response: response, sms_gateway: "sms_just" }
        attrs[:status] = response['result'] != 'Success' ? 'fail' : 'sent'
        attrs[:sent_on] = Time.now if attrs[:status] == 'sent'
        sms.set(attrs)
        return attrs
      end
    end

    # Knowlarity sms Gateway
    class KnowlarityWorker
      include Sidekiq::Worker
      # Initializes parameters: send_to,msg,method,userid,auth_scheme,password,v(version),format,mask
      # override_dnd,msg_type
      def perform(sms_id)
        sms = ::Sms.where(id: sms_id).first
        if sms && sms.to.present?
          client = sms.booking_portal_client
          params={}
          headers={}
          params[:is_file] = 'no'
          params[:sms_to] = sms.to.first
          params[:sms_text] = sms.body
          headers[:auth_key] = client.sms_provider_password
          params[:sms_from] = client.sms_mask
          params[:sms_type] = 'trans'    #promo
          url = "http://etsrds.kapps.in/webapi/amura/api/amura_sms_api.py"
          begin
            params = params.with_indifferent_access
            headers = headers.with_indifferent_access
            resp = JSON.parse RestClient::Request.execute(method: :post, url: url, payload: params, headers: headers)
            status = (resp['status'] == 'success' ? 'sent' : 'failed')
            attrs = {response: resp, status: status}
            attrs[:sent_on] = Time.now if status == 'sent'
            attrs[:sms_gateway] = 'knowlarity'
            sms.set(attrs)
            {status: resp["status"], remote_id: resp['client_api_resp']['messages'].first['messageId']}
          rescue
            sms.update_attributes({status: 'failed'})
            {status: "failed",remote_id: ""}
          end
        end
      end
    end

    # Twilio sms service provider for international sms.
    class TwilioWorker
      include Sidekiq::Worker

      def perform sms_id
        sms = ::Sms.find sms_id
        client = sms.booking_portal_client
        params = {}
        params[:from] = client.twilio_virtual_number # "+16413231111"
        params[:dest_mobileno] = sms.to.first
        params[:message] = sms.body
        params[:username] = client.twilio_account_sid # "ACa7a3b2dbd165abed9344f1b93307118f"
        params[:pass] = client.twilio_auth_token # "74ace8abc1cb4c96d4d579c04a68ef33"

        twilio_client = ::Twilio::REST::Client.new(params[:username], params[:pass])
        begin
          message = twilio_client.messages.create(
            body: sms.body,
            to: params[:dest_mobileno],
            from: params[:from])
          if message.status == 'queued'
            sms.set(status: 'sent', sent_on: Time.now, sms_gateway: 'twilio')
          else
            sms.set(status: 'fail', remote_id: message.status)
          end
        rescue Twilio::REST::RestError => e
          sms.set(status: 'fail', remote_id: e.message)
        end
      end
    end
  end
end
