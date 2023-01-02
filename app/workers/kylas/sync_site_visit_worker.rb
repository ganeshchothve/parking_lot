# frozen_string_literal: true
require 'net/http'

module Kylas
  # service to sync lead as deal & contact in Kylas
  class SyncSiteVisitWorker
    include Sidekiq::Worker

    def perform site_visit_id
      site_visit = SiteVisit.where(id: site_visit_id).first
      if site_visit.present?
        user = site_visit.lead.try(:owner)
        Kylas::CreateMeeting.new(user, site_visit, {run_in_background: false}).call
      end
    end
  end
end
