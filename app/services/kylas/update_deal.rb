require 'uri'
require 'json'
require 'net/http'

module Kylas
  # Used for update deal
  class UpdateDeal < BaseService
    attr_reader :user, :entity, :params

    def initialize(user, entity, params = {})
      @user = user
      @entity = entity
      @params = params
    end

    def call
      return if user.blank? || entity.blank?

      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Put.where(base_id: kylas_base.id, resource_class: 'BookingDetail', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if api.present?
          if params[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'BookingDetail', entity.id, params)
          else
            response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'BookingDetail', entity.id, params)
          end
        end
      end
    end
  end
end