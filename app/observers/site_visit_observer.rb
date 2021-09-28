class SiteVisitObserver < Mongoid::Observer
  def after_create site_visit
    site_visit.third_party_references.each(&:update_references)
  end
end
