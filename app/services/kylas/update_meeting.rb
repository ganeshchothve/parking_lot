# frozen_string_literal: true
require 'net/http'

module Kylas
  # service to update meeting in kylas
  class UpdateMeeting < BaseService

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
        api = Crm::Api::Put.where(base_id: kylas_base.id, resource_class: 'SiteVisit', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if api.present?
          meeting_params = update_participants(kylas_base)
          if params[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'SiteVisit', entity.id, meeting_params)
          else
            response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'SiteVisit', entity.id, meeting_params)
          end
        end
      end
    end

    def update_participants kylas_base
      admin = kylas_base.user
      if admin.present?
        payload = 
        {
          "id": admin.kylas_user_id,
          "entity": "user"
        },
        {
          "id": entity.user.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)),
          "entity": "contact"
        }
      end
      payload
    end
  end
end