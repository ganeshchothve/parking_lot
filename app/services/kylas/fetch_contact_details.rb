# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch contact details
  class FetchContactDetails
    attr_reader :user, :contact_ids, :is_single_contact

    def initialize(user, contact_ids, is_single_contact = false)
      @user = user
      @contact_ids = contact_ids
      @is_single_contact = is_single_contact
    end

    def call
      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/search/contact")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      if user.kylas_api_key?
        request['api-key'] = user.kylas_api_key
      elsif user.kylas_refresh_token
        request['Authorization'] = "Bearer #{user.fetch_access_token}"
      end
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'

      request.body = JSON.dump(
        {
          'fields': %w[firstName lastName emails phoneNumbers id],
          'jsonRule': {
            'rules': [{
              'operator': 'in',
              'id': 'id',
              'field': 'id',
              'type': 'double',
              'value': contact_ids.join(',')
            }],
            'condition': 'AND',
            'valid': true
          }
        }
      )
      response = https.request(request)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        parsed_response = JSON.parse(response.body)
        # filter_required_data = parsed_response['content'].map do |contact|
        #   result = contact.slice('emails', 'phoneNumbers')
        #   result['firstName'] = contact['firstName']
        #   result['lastName'] = contact['lastName']
        # end

        contacts_data = []
        parsed_response['content'].each do |contact|
          contact = contact.with_indifferent_access
          contacts_data << {
            id: contact[:id],
            emails: (contact[:emails] || []),
            phoneNumbers: (contact[:phoneNumbers] || []),
            firstName: contact[:firstName],
            lastName: contact[:lastName]
          }
        end
        # single contact response in hash
        contacts_data = ((is_single_contact ? contacts_data.first : contacts_data) rescue nil)
        { success: true, data: contacts_data }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchContactDetails - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchContactDetails - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchContactDetails - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchContactDetails - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end
  end
end
