require "uri"
require "net/http"
require "net/https"

module Zoho
  class Sign
    SCOPES = ["ZohoSign.documents.ALL"]
    CLIENT_ID = '1000.9GM9U969TR3W6GZYJU3W5DTFSJR2KS'
    CLIENT_SECRET = '776c4eb58da81056cc6ec5f5ed9db99a9a6bcefae8'
    REDIRECT_PATH = "admin/client/document_sign/callback"

    def self.authorization_url base_domain
      "https://accounts.zoho.in/oauth/v2/auth?scope=#{SCOPES.join(',')}&client_id=#{CLIENT_ID}&state=#{SecureRandom.hex}&response_type=code&redirect_uri=#{base_domain}#{REDIRECT_PATH}&access_type=offline&prompt=Consent"
    end

    def self.authorize_first_token!(code, base_domain, document_sign)
      url = URI("https://accounts.zoho.in/oauth/v2/token")
      https = Net::HTTP.new(url.host, url.port);
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      form_data = [
        ['client_id', CLIENT_ID],
        ['client_secret', CLIENT_SECRET],
        ['redirect_uri', "#{base_domain}#{REDIRECT_PATH}"],
        ['code', code],
        ['grant_type', 'authorization_code']
      ]
      request.set_form form_data, 'multipart/form-data'
      response = https.request(request)
      json = JSON.parse(response.read_body).with_indifferent_access
      document_sign.access_token = json['access_token']
      document_sign.refresh_token = json['refresh_token']
      document_sign.save!
    end

    def self.refresh_token!(base_domain, document_sign)
      url = URI("https://accounts.zoho.in/oauth/v2/token")
      https = Net::HTTP.new(url.host, url.port);
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      form_data = [
        ['refresh_token', document_sign.refresh_token],
        ['client_id', CLIENT_ID],
        ['client_secret', CLIENT_SECRET],
        ['redirect_uri', "#{base_domain}#{REDIRECT_PATH}"],
        ['grant_type', 'refresh_token']
      ]
      request.set_form form_data, 'multipart/form-data'
      response = https.request(request)
      json = JSON.parse(response.read_body).with_indifferent_access
      document_sign.access_token = json['access_token']
      document_sign.save!
    end

    def self.create_and_sign(asset, document_sign, options={})
      document_sign_detail = DocumentSignDetail.find_or_create_by(asset_id: asset.id, document_sign_id: document_sign.id)
      document_sign_detail.assign_attributes(request_name: options["request_name"], recipient_name: options["recipient_name"], recipient_email: options["recipient_email"])
      if document_sign_detail.save
        create(asset, document_sign, document_sign_detail)
        sign(document_sign, document_sign_detail) if document_sign_detail.status == 'created'
      else
        Rails.logger.error "Errors storing document sign_detail - #{document_sign_detail.errors.to_sentence}"
      end
    end

    def self.create(asset, document_sign, document_sign_detail)
      data = '{
        "requests":{
          "request_name":"'+ document_sign_detail.request_name + '",
          "is_sequential": false,
          "expiration_days":10,
          "email_reminders":true,
          "reminder_period": 1,
          "actions": [{
              "recipient_name": "' + document_sign_detail.recipient_name + '",
              "recipient_email": "' + document_sign_detail.recipient_email + '",
              "action_type": "SIGN"
            }
          ]
        }
      }'
      url = URI("https://sign.zoho.in/api/v1/requests")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Authorization"] = "Zoho-oauthtoken #{document_sign.get_access_token}"
      File.open("#{Rails.root}/exports/#{document_sign_detail.id}_#{asset.assetable.class.to_s.downcase}.pdf", "wb") do |file|
        file << open(asset.file.url).read
      end
      file_data = [
        ['file', File.open("#{Rails.root}/exports/#{document_sign_detail.id}_#{asset.assetable.class.to_s.downcase}.pdf")],
        ['data', data]
      ]
      # request.set_form_data form_data, 'multipart/form-data'
      request.set_form file_data, 'multipart/form-data'
      response = nil
      response = http.request(request)
      case response.code
      when "200"
        j = JSON.parse response.read_body
        document_sign_detail.assign_attributes(request_id: j['requests']['request_id'], action_id: j['requests']['actions'].first['action_id'], document_id: j['requests']['document_ids'].first['document_id'], status: 'created', response: response.read_body)
      else
        document_sign_detail.assign_attributes(status: 'create_failed', response: response.read_body)
      end
      document_sign_detail.save
    end
  
    def self.sign document_sign, document_sign_detail
      data = '{
        "requests":{
          "request_name":"' + document_sign_detail.request_name + '",
          "deleted_actions": [],
          "actions": [{
              "action_id": "' + document_sign_detail.action_id + '",
              "action_type": "SIGN",
              "deleted_fields": [],
              "is_bulk": false,
              recipient_phonenumber: "",
              "recipient_name": "' + document_sign_detail.recipient_name + '",
              "recipient_email": "' + document_sign_detail.recipient_email + '",
              "fields": [{
                  "document_id": "' + document_sign_detail.document_id + '",
                  "action_id": "' + document_sign_detail.action_id + '",
                  "field_type_name": "Signature",
                  "field_category": "image",
                  "field_label": "Signature",
                  "is_mandatory": true,
                  "field_name": "Signature",
                  "description_tooltip": "Please sign here",
                  "page_no": 0,
                  "abs_width": 500,
                  "abs_height": 100,
                  "y_coord": 5,
                  "x_coord": 60
                }
              ]
            }
          ]
        }
      }'
  
      url = URI("https://sign.zoho.in/api/v1/requests/#{document_sign_detail.request_id}/submit")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Authorization"] = "Zoho-oauthtoken #{document_sign.get_access_token}"
      file_data = [
        ['data', data]
      ]
      # request.set_form_data form_data, 'multipart/form-data'
      request.set_form file_data, 'multipart/form-data'
      response = nil
      response = http.request(request)
      case response.code
      when "200"
        document_sign_detail.assign_attributes(status: 'signed', response: response.read_body)
      else
        document_sign_detail.assign_attributes(status: 'sign_failed', response: response.read_body)
      end
      document_sign_detail.save
    end
  
    def self.download document_sign, document_sign_detail
      asset = document_sign_detail.asset
      str = "https://sign.zoho.in/api/v1/requests/#{document_sign_detail.request_id}/documents/#{document_sign_detail.document_id}/pdf"
      url = URI(str)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Zoho-oauthtoken #{document_sign.get_access_token}"
      response = nil
      response = http.request(request)
      response.read_body
      asset.file = FileIo.new(response.read_body, "signed-#{asset.file_name}")
      if asset.save
        asset
      else
        {errors: asset.errors.full_messages.uniq}
      end
    end
  
    def self.recall document_sign, request_id
      url = URI("https://sign.zoho.in/api/v1/requests/#{request_id}/recall")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Authorization"] = "Zoho-oauthtoken #{document_sign.get_access_token}"
      response = nil
      response = http.request(request)
      JSON.parse response.read_body
    end
  
    def self.remind document_sign, request_id
      url = URI("https://sign.zoho.in/api/v1/requests/#{request_id}/remind")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Authorization"] = "Zoho-oauthtoken #{document_sign.get_access_token}"
      response = nil
      response = http.request(request)
      JSON.parse response.read_body
    end
  end
end