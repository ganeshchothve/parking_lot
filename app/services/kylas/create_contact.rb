require 'uri'
require 'json'
require 'net/http'

module Kylas
  # service used for create contact in Kylas
  class CreateContact < BaseService
    attr_reader :user, :contact, :options

    def initialize(user, contact, options={})
      @user = user
      @contact = contact
      @options = options
    end

    def call
      return if user.blank? || contact.blank? || request_headers.blank?
      if options[:check_uniqueness]
        response = Kylas::FetchUniquenessStrategy.new('contact', contact).call
        if response[:success]
          uniqueness_strategy = response[:data]["field"].downcase
          if(uniqueness_strategy == "email" && contact.email.present?) || 
            (uniqueness_strategy == "phone" && contact.phone.present?) || 
            (uniqueness_strategy == "email_phone" && (contact.email.present? || contact.phone.present?))
            search_response = Kylas::SearchEntity.new(contact, 'contact', uniqueness_strategy, user, {run_in_background: false}).call
            if search_response[:api_log].present? && search_response[:api_log][:status] == "Success"
              search_result = search_response[:api_log][:response].first
              if search_result["content"].blank?
                response = sync_contact_to_kylas
              else
                contact.set(kylas_contact_id: search_result["content"].first["id"]) if contact.kylas_contact_id.blank?
              end
            end
          else
            response = sync_contact_to_kylas
          end
        end
      else
        response = sync_contact_to_kylas
      end
    end

    def sync_contact_to_kylas
      kylas_base = Crm::Base.where(domain: ENV_CONFIG.dig(:kylas, :base_url), booking_portal_client_id: user.booking_portal_client.id).first
      if kylas_base
        api = Crm::Api::Post.where(base_id: kylas_base.id, resource_class: 'User', event: 'CreateContact', is_active: true, booking_portal_client_id: user.booking_portal_client.id).first
        if api.present?
          if options[:run_in_background]
            response = Kylas::Api::ExecuteWorker.perform_async(user.id, api.id, 'User', contact.id, {})
          else
            response = Kylas::Api::ExecuteWorker.new.perform(user.id, api.id, 'User', contact.id, {})
          end

          if response.present?
            log_response = response[:api_log]
            if log_response.present?
              if log_response[:status] == "Success"
                contact.set(kylas_contact_id: log_response[:response].first["id"])
              end
            end
            response
          end
        end
      end
    end
  end
end