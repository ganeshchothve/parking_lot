# frozen_string_literal: true

require 'net/http'

module Kylas
  # Search Entity
  class SearchEntity < BaseService
    attr_accessor :entity, :entity_type, :field, :user, :params

    def initialize(entity, entity_type, field, user, params={run_in_background: true})
      @entity = entity
      @entity_type = entity_type
      @field = field
      @user = user
      @params = params
    end

    def call
      return if user.blank?

      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Post.where(base_id: kylas_base.id, resource_class: 'User', is_active: true, event: 'SearchContact').first
        payload = { entity_value: find_entity_value_using_field }
        if params[:run_in_background]
          response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'User', entity.id, payload)
        else
          response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'User', entity.id, payload)
        end
      end
      return response
    end

    def find_entity_value_using_field
      entity_value = if field == "email"
        entity.email
      elsif field == "phone"
        phone = Phonelib.parse(entity.phone) 
        phone.national(false).sub(/^0/, '')
      elsif field == "email_phone"
        if entity.email.present?
          entity.email
        elsif entity.phone.present?
          phone = Phonelib.parse(entity.phone) 
          phone.national(false).sub(/^0/, '')
        end
      end
    end
  end
end
