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

    def self.create(document_path, document_sign, options={})
      data = '{
        "requests":{
          "request_name":"Hello Ketan",
          "is_sequential": false,
          "expiration_days":10,
          "email_reminders":true,
          "reminder_period": 1,
          "actions": [{
              "recipient_name": "Ketan",
              "recipient_email": "ketan.sabnis@gmail.com",
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
      file_data = [
        ['file', File.open(document_path)],
        ['data', data]
      ]
      # request.set_form_data form_data, 'multipart/form-data'
      request.set_form file_data, 'multipart/form-data'
      response = nil
      response = http.request(request)
      j = JSON.parse response.read_body
      request_id = j['requests']['request_id']
      action_id = j['requests']['actions'].first['action_id']
      document_id = j['requests']['document_ids'].first['document_id']
      {request_id: request_id, action_id: action_id, document_id: document_id}
    end
  
    def self.sign document_sign, request_id, action_id, document_id
      data = '{
        "requests":{
          "request_name":"Hello Ketan",
          "deleted_actions": [],
          "actions": [{
              "action_id": "' + action_id + '",
              "action_type": "SIGN",
              "deleted_fields": [],
              "is_bulk": false,
              recipient_phonenumber: "",
              "recipient_name": "Ketan",
              "recipient_email": "ketan.sabnis@gmail.com",
              "fields": [{
                  "document_id": "' + document_id + '",
                  "action_id": "' + action_id + '",
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
  
      url = URI("https://sign.zoho.in/api/v1/requests/#{request_id}/submit")
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
      JSON.parse response.read_body
    end
  
    def self.download document_sign, request_id, document_id
      str = "https://sign.zoho.in/api/v1/requests/#{request_id}/documents/#{document_id}/pdf"
      url = URI(str)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Zoho-oauthtoken #{document_sign.get_access_token}"
      response = nil
      response = http.request(request)
      response.read_body
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