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
    end
  end

  def after_create receipt
    receipt.moved_to_clearance_pending if receipt.pending?
    SelldoLeadUpdater.perform_async(receipt.user_id.to_s, {stage: 'payment_done', token_number: receipt.token_number.present?}) if (receipt.offline? || (receipt.online? && receipt.success? ))
  end

  def after_update receipt
    SelldoLeadUpdater.perform_async(receipt.user_id.to_s, {stage: 'payment_done', token_number: (receipt.token_number_changed? && receipt.token_number.present?)}) if (receipt.offline? || (receipt.online? && receipt.success? ))
  end
end
