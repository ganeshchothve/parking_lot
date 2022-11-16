require 'uri'
require 'json'
require 'net/http'

module Kylas
  # service used for create contact in Kylas
  class CreateContact < BaseService
    attr_reader :user, :contact, :options

    def initialize(user, contact, options={})
      @user = user
      @contact = contact
      @options = options
    end

    def call
      return if user.blank? || contact.blank? || request_headers.blank?
      if options[:check_uniqueness]
        response = Kylas::FetchUniquenessStrategy.new('contact', user).call
        if response[:success]
          uniqueness_strategy = response[:data]["field"].downcase
          if(uniqueness_strategy == "email" && user.email.present?) || 
            (uniqueness_strategy == "phone" && user.phone.present?) || 
            (uniqueness_strategy == "email_phone" && (user.email.present? || user.phone.present?))
            search_response = Kylas::SearchEntity.new(user, 'contact', uniqueness_strategy, user, {run_in_background: false}).call
            if search_response[:api_log].present? && search_response[:api_log][:status] == "Success"
              search_result = search_response[:api_log][:response].first
              if search_result["content"].blank?
                response = sync_contact_to_kylas
                user.set(kylas_contact_id: response.dig(:data, :id))
              else
                user.set(kylas_contact_id: search_result["content"].first["id"]) if user.kylas_contact_id.blank?
              end
            end
          else
            response = sync_contact_to_kylas
            user.set(kylas_contact_id: response.dig(:data, :id))
          end
        end
      else
        sync_contact_to_kylas
      end
    end

    def sync_contact_to_kylas
      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/contacts")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url, request_headers)
      request.body = JSON.dump(parse_contact(contact))
      response = https.request(request)
      api_log = ApiLog.new
      case response
      when Net::HTTPOK, Net::HTTPSuccess
        api_log.assign_attributes(request_url: url, request: [parse_contact(contact)], response: [(JSON.parse(response.body) rescue {})], resource: contact, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        response = JSON.parse(response.body)
        { success: true, data: parse_response(response) }
      when Net::HTTPBadRequest
        Rails.logger.error 'CreateContact - 400'
        api_log.assign_attributes(request_url: url, request: ([(parse_contact(contact) rescue {})]), response: [(JSON.parse(response.body) rescue {})], resource: contact, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'CreateContact - 404'
        api_log.assign_attributes(request_url: url, request: ([(parse_contact(contact) rescue {})]), response: [(JSON.parse(response.message) rescue 'Invalid Data!')], resource: contact, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'CreateContact - 500'
        api_log.assign_attributes(request_url: url, request: ([(parse_contact(contact) rescue {})]), response: [(JSON.parse(response.message) rescue 'Server Error!')], resource: contact, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'CreateContact - 401'
        api_log.assign_attributes(request_url: url, request: ([(parse_contact(contact) rescue {})]), response: [(JSON.parse(response.message) rescue 'Unauthorized')], resource: contact, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false, error: 'Unauthorized' }
      else
        api_log.assign_attributes(request_url: url, request: ([(parse_contact(contact) rescue {})]), response: [(JSON.parse(response.message) rescue 'Internal server error!')], resource: contact, response_type: "Hash", booking_portal_client: user.booking_portal_client)
        api_log.save
        { success: false }
      end
    end 

    def parse_response(response)
      response = response.with_indifferent_access
      parse_response = {}
      parse_response[:id] = response[:id]
      parse_response[:name] = "#{response[:firstName]} #{response[:lastName]}"
      parse_response
    end

    def parse_contact(contact)
      email = [{:type=>"OFFICE", :value=>contact.email, :primary=>true}]
      if contact.phone.present?
        phone = Phonelib.parse(contact.phone)
        phones = [{:type=>"MOBILE", :code=> phone.country, :dialCode=>"+#{phone.country_code}", :value=> phone.national(false).sub(/^0/, ''), :primary=>true}]
      end
      if contact.email.present?
        emails = [{type: "OFFICE", value: contact.email, primary: true}]
      end
      parsed_contact = {
        firstName: contact.first_name,
        lastName: contact.last_name,
        facebook: nil,
        twitter: nil,
        linkedin: nil,
        customFieldValues: {}
      }
      parsed_contact.merge!(emails: emails) if (defined?(emails) && emails.present?)
      parsed_contact.merge!(phoneNumbers: phones) if (defined?(phones) && phones.present?)
      parsed_contact
    end
  end
end