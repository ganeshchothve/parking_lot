require 'uri'
require 'json'
require 'net/http'

module Kylas
  # service used for create contact in Kylas
  class UpdateContact < BaseService
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
          if (uniqueness_strategy == "email" && contact.email.present?) ||
             (uniqueness_strategy == "phone" && contact.phone.present?) ||
             (uniqueness_strategy == "email_phone" && (contact.email.present? || contact.phone.present?))
            search_response = Kylas::SearchEntity.new(contact, 'contact', uniqueness_strategy, user, {run_in_background: false}).call rescue {}
            if search_response.present? && search_response.dig(:api_log, :status) == "Success"
              search_result = search_response[:api_log][:response].first
              if search_result["content"].blank?
                response = sync_contact_to_kylas
                user.set(kylas_contact_id: response.dig(:data, :id))
                response
              else
                response_contact_id = search_result["content"].first["id"]
                return { success: false, error: "Contact ID: #{response_contact_id}, The entered Phone number or email already exists on another contact!" }
              end
            end
          else
            response = sync_contact_to_kylas
            user.set(kylas_contact_id: response.dig(:data, :id))
            response
          end
        end
      else
        response = sync_contact_to_kylas
        response
      end
    end

    def sync_contact_to_kylas
      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Post.where(base_id: kylas_base.id, resource_class: 'User', event: 'UpdateContact', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if api.present?
          if options[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'User', contact.id, {})
          else
            response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'User', contact.id, {})
          end
        end
      end
    end
  end
end