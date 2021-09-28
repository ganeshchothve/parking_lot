class SiteVisitObserver < Mongoid::Observer
  def before_validation site_visit
    if site_visit.time_slot_id_changed? && site_visit.time_slot.present?
      tz = Time.use_zone(site_visit.user.time_zone) { Time.zone }
      tz_str = ActiveSupport::TimeZone.seconds_to_utc_offset(tz.utc_offset)
      sv.scheduled_on = "#{site_visit.time_slot.start_time_to_s} #{tz_str}" if site_visit.time_slot&.start_time_to_s.present?
    end
  end

  def before_save site_visit
    if site_visit.site_visit_type == 'token_slot'
      if (site_visit.scheduled_on_changed? && site_visit.scheduled_on.present?) || (site_visit.status_changed? && site_visit.status.present?)
        SelldoLeadUpdater.perform_async(site_visit.lead_id.to_s, {action: 'add_slot_details', slot_details: site_vist.time_slot&.to_s(receipt.user&.time_zone), slot_status: site_visit.slot_status})
      end
    end
  end

  def after_create site_visit
    site_visit.third_party_references.each(&:update_references)
  end
end
