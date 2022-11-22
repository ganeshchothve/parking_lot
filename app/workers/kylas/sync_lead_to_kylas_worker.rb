# frozen_string_literal: true
require 'net/http'

module Kylas
  # service to sync lead as deal & contact in Kylas
  class SyncLeadToKylasWorker
    include Sidekiq::Worker

    def perform lead_id, site_visit_id=nil, params={}
      lead = Lead.where(id: lead_id).first
      site_visit = SiteVisit.where(id: site_visit_id).first
      if lead.present?
        user = lead.user
        if user.present? && user.booking_portal_client.is_marketplace? && user.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)).blank?
          Kylas::CreateContact.new(user, user, {check_uniqueness: true}).call
          if lead.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)).blank?
            Kylas::CreateDeal.new(user, lead, {run_in_background: false}).call
          end
          if site_visit.present?
            Kylas::SyncSiteVisitWorker.perform_async(site_visit.id.to_s)
          end
        end
      end
    end
  end
end