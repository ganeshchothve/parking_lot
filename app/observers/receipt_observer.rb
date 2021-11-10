class ReceiptObserver < Mongoid::Observer
  def before_validation(receipt)
    _event = receipt.event.to_s
    receipt.event = nil
    if _event.present? && (receipt.aasm.current_state.to_s != _event.to_s)
      if receipt.send("may_#{_event.to_s}?")
        receipt.aasm.fire!(_event.to_sym)
      else
        receipt.errors.add(:status, 'transition is invalid')
      end
    end
  end

  def before_save(receipt)
    receipt.receipt_id = receipt.generate_receipt_id
    if receipt.booking_detail_id_changed? && (booking_detail = receipt.booking_detail.presence)
      receipt.project = booking_detail.project
      receipt.lead = booking_detail.lead
      receipt.user = booking_detail.lead.user
      receipt.manager_id = booking_detail.manager_id || receipt.lead.active_cp_lead_activities.first.try(:user_id)
    end
    receipt.manager_id = receipt.lead.active_cp_lead_activities.first.try(:user_id) if receipt.manager_id.blank?

    # Create a Sitevisit if time slot is assigned to token
    #
    if receipt.time_slot_id_changed? && receipt.time_slot.present?
      sv = SiteVisit.where(site_visit_type: 'token_slot', lead: receipt.lead, project: receipt.project, status: {'$in': %w(scheduled pending)}).first
      sv ||= SiteVisit.new(
        user: receipt.user,
        lead: receipt.lead,
        creator: receipt.user,
        project: receipt.project,
        site_visit_type: 'token_slot'
      )

      sv.time_slot = receipt.time_slot
      sv.save

      # push SV in sell.do
      crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url)).first
      if crm_base.present?
        api, api_log = sv.push_in_crm(crm_base)
      end
    end
  end

  def after_create receipt
    receipt.moved_to_clearance_pending if receipt.pending?
    if receipt.offline? || (receipt.online? && receipt.success?)
      receipt.lead.payment_done! if receipt.lead.may_payment_done?
      SelldoLeadUpdater.perform_async(receipt.lead_id.to_s, {stage: 'payment_done'}) if receipt.token_number.present?
    end
  end

  def after_update receipt
    if receipt.offline? || (receipt.online? && receipt.success?)
      receipt.lead.payment_done! if receipt.lead.may_payment_done?
      SelldoLeadUpdater.perform_async(receipt.lead_id.to_s, {stage: 'payment_done'}) if receipt.token_number.present?
    end
  end
end
