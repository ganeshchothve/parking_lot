# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to create product in kylas
  class CreateWebhook < BaseService

    attr_accessor :client, :entity, :params

    def initialize(client, params={})
      @client = client
      @entity = client
      @params = params
    end

    def call
      return if client.blank?

      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: client.id).first
      if kylas_base
        api = Crm::Api::Post.where(base_id: kylas_base.id, resource_class: 'Client', is_active: true, booking_portal_client_id: client.id).first
        if api.present?
          if params[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(client.id, api.id, 'Client', entity.id, {})
          else
            response = Kylas::Api::ExecuteWorker.new.perform(client.id, api.id, 'Client', entity.id, {})
          end
        end
      end
    end
  end
end
