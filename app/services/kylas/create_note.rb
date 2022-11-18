# frozen_string_literal: true
require 'net/http'

module Kylas
  #service to create note in kylas
  class CreateNote < BaseService

    attr_accessor :user, :note, :params

    def initialize(user, note, params={})
      @user = user
      @note = note
      @params = params
    end

    def call
      return if user.blank?

      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Post.where(base_id: kylas_base.id, resource_class: 'Note', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if api.present?
          if params[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'Note', note.id, {})
          else
            response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'Note', note.id, {})
          end
        end
        log_response = response[:api_log]
        if log_response.present?
          if log_response[:status] == "Success"
            entity.set(kylas_note_id: log_response[:response].first["id"])
          end
        end
      end

    end
  end
end