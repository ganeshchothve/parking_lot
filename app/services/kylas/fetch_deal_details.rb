# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch deal details
  class FetchDealDetails
    attr_reader :entity_id, :user

    def initialize(entity_id, user)
      @entity_id = entity_id
      @user = user
    end

    def call
      url = URI("#{APP_KYLAS_HOST}/#{APP_KYLAS_VERSION}/deals/#{entity_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      if user.kylas_api_key?
        request['api-key'] = user.kylas_api_key
      elsif user.kylas_refresh_token
        request['Authorization'] = "Bearer #{user.fetch_access_token}"
      end
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'

      response = https.request(request)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        parsed_response = JSON.parse(response.body)
        { success: true, data: parsed_response }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchDealDetails - 400'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchDealDetails - 404'
        { success: false, error: 'Invalid Data!' }
      when Net::HTTPServerError
        Rails.logger.error 'FetchDealDetails - 500'
        { success: false, error: 'Server Error!' }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchDealDetails - 401'
        { success: false, error: 'Unauthorized' }
      else
        { success: false }
      end
    end

    private

    def entity_details(parsed_response)
      deal_details = { description: parsed_response['name'] }

      # Amount
      actual_value = parsed_response['actualValue']
      currency_amount = actual_value.present? ? actual_value : parsed_response['estimatedValue']
      amount = currency_amount['value'].to_i

      # Standard PickList
      currency_data = Kylas::FetchStandardPickList.new(user).call
      currency = currency_value(currency_data[:currencies], currency_amount['currencyId']) if currency_data[:success]
      # Contact Details
      contact_ids = parsed_response['associatedContacts'].map { |v| v['id'] }.compact
      
      if contact_ids
        contact_details = Kylas::FetchContactDetails.new(user, contact_ids).call
        contact_details = contact_details[:data] if contact_details[:success]
      end

      deal_details.merge!({ currency: currency, amount: amount, contact: contact_details })
    end

    def currency_value(currencies, currency_id)
      currency_val = currencies.select { |currency| currency['id'] == currency_id }.first
      currency_val['name'] if currency_val
    end
  end
end
