# frozen_string_literal: true
require 'net/http'

module Kylas
  # service to update deal in kylas
  class DealUpdate < BaseService

    attr_accessor :user, :entity, :params

    def initialize(user, entity, params={run_in_background: true})
      @user = user
      @entity = entity
      @params = params
    end

    def call
      return if user.blank?

      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Put.where(base_id: kylas_base.id, resource_class: 'Lead', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if params[:run_in_background]
          response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'Lead', entity.id, {})
        else
          response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'Lead', entity.id, {})
        end
      end
    end
  end
end