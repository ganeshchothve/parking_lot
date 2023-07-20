class SiteVisitDeactivateWorker
  include Sidekiq::Worker

  def perform site_visit_id, client_id
    site_visit = SiteVisit.where(booking_portal_client_id: client_id, _id: site_visit_id).first
    if site_visit
      if site_visit.scheduled? && Time.current >= (site_visit.scheduled_on + ::SiteVisit::TIME_TILL_INACTIVE)
        site_visit.inactive!
      end
    end
  end
end
