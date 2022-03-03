class SiteVisitObserver < Mongoid::Observer
  include ApplicationHelper

  def before_validation site_visit
    # Handle state transitions
    _event = site_visit.event.to_s
    site_visit.event = nil
    if _event.present?
      if site_visit.send("may_#{_event.to_s}?")
        site_visit.aasm(:status).fire!(_event.to_sym)
      else
        site_visit.errors.add(:status, 'transition is invalid')
      end
    end
    approval_event = site_visit.approval_event.to_s
    site_visit.approval_event = nil
    if approval_event.present?
      if site_visit.send("may_#{approval_event.to_s}?")
        site_visit.aasm(:approval_status).fire!(approval_event.to_sym)
      else
        site_visit.errors.add(:approval_status, 'transition is invalid')
      end
    end

    # Handle time slot for token visit
    if site_visit.time_slot_id_changed? && site_visit.time_slot.present?
      tz = Time.use_zone(site_visit.user.time_zone) { Time.zone }
      tz_str = ActiveSupport::TimeZone.seconds_to_utc_offset(tz.utc_offset)
      site_visit.scheduled_on = "#{site_visit.time_slot.start_time_to_s} #{tz_str}" if site_visit.time_slot&.start_time_to_s.present?
    end

    # Set project & user
    site_visit.project_id = site_visit.lead&.project_id if site_visit.project_id.blank?
    site_visit.user_id = site_visit.lead&.user_id if site_visit.user_id.blank?
    # Set manager if present on lead
    site_visit.manager_id = site_visit.lead&.manager_id if site_visit.manager_id.blank?
    site_visit.channel_partner_id = site_visit.manager&.channel_partner_id if site_visit.channel_partner_id.blank? && site_visit.manager.present?
    site_visit.cp_manager_id = site_visit.manager&.manager_id if site_visit.cp_manager_id.blank? && site_visit.manager
    site_visit.cp_admin_id = site_visit.cp_manager&.manager_id if site_visit.cp_admin_id.blank? && site_visit.cp_manager

    # Set created_by
    if site_visit.created_by.blank?
      site_visit.created_by = site_visit.creator&.role
    end
  end

  def before_save site_visit
    if site_visit.site_visit_type == 'token_slot'
      if (site_visit.scheduled_on_changed? && site_visit.scheduled_on.present?) || (site_visit.status_changed? && site_visit.status.present?)
        SelldoLeadUpdater.perform_async(site_visit.lead_id.to_s, {action: 'add_slot_details', slot_details: site_visit.time_slot&.to_s(site_visit.user&.time_zone), slot_status: site_visit.slot_status})
      end
    end

    if current_client.external_api_integration?
      if Rails.env.staging? || Rails.env.production?
        SiteVisitObserverWorker.perform_async(site_visit.id.to_s, 'update', site_visit.changes.merge(site_visit.notes.select {|x| x.new_record? && x.changes.present?}.first&.changes&.slice('note') || {}))
      else
        SiteVisitObserverWorker.new.perform(site_visit.id, 'update', site_visit.changes.merge(site_visit.notes.select {|x| x.new_record? && x.changes.present?}.first&.changes&.slice('note') || {}))
      end
    end
  end

  def after_create site_visit
    site_visit.third_party_references.each(&:update_references)

    if current_client.external_api_integration?
      if Rails.env.staging? || Rails.env.production?
        SiteVisitObserverWorker.perform_async(site_visit.id.to_s, 'create', site_visit.changes)
      else
        SiteVisitObserverWorker.new.perform(site_visit.id.to_s, 'create', site_visit.changes)
      end
    end
  end

  def after_save site_visit
    # calculate incentive and generate an invoice for the respective site visit
    site_visit.calculate_incentive if site_visit.project.incentive_calculation_type?("calculated")
    # once the site visit is cancelled, the invoice in tentative state should move to rejected state
    if site_visit.approval_status_changed? && site_visit.approval_status == 'rejected'
      site_visit.invoices.where(status: 'tentative').update_all(status: 'rejected', rejection_reason: 'Site Visit has been cancelled')
    end
    site_visit.invoices.where(status: 'tentative').update_all(status: 'draft') if site_visit.actual_incentive_eligible?
  end
end
