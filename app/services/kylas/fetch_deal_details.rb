# frozen_string_literal: true

require 'net/http'

module Kylas
  # Fetch deal details
  class FetchDealDetails < BaseService
    attr_reader :entity_id, :user

    def initialize(entity_id, user)
      @entity_id = entity_id
      @user = user
    end

    def call
      url = URI(base_url+"/deals/#{entity_id}")

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url, request_headers)

      response = https.request(request)
      parsed_response = JSON.parse(response.body)

      case response
      when Net::HTTPOK, Net::HTTPSuccess
        { success: true, data: parsed_response }
      when Net::HTTPBadRequest
        Rails.logger.error 'FetchDealDetails - 400'
        { success: false, error: 'Invalid Data!', response: parsed_response }
      when Net::HTTPNotFound
        Rails.logger.error 'FetchDealDetails - 404'
        { success: false, error: 'Invalid Data!', response: parsed_response }
      when Net::HTTPServerError
        Rails.logger.error 'FetchDealDetails - 500'
        { success: false, error: 'Server Error!', response: parsed_response }
      when Net::HTTPUnauthorized
        Rails.logger.error 'FetchDealDetails - 401'
        { success: false, error: 'Unauthorized', response: parsed_response }
      else
        { success: false, response: parsed_response }
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
