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
