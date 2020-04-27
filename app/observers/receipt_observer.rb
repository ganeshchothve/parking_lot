class ReceiptObserver < Mongoid::Observer
  def before_validation(receipt)
    if receipt.event.present? && (receipt.aasm.current_state.to_s != receipt.event.to_s)
      if receipt.send("may_#{receipt.event.to_s}?")
        receipt.aasm.fire!(receipt.event.to_sym)
      else
        receipt.errors.add(:status, 'transition is invalid')
      end
    end
  end

  def before_save(receipt)
    receipt.receipt_id = receipt.generate_receipt_id
    if receipt.status_changed? && receipt.status == "success"
      receipt.assign!(:order_id) if receipt.order_id.blank?
    end
  end

  # def after_save(receipt)
  #   _event = receipt.event
  #   receipt.event = nil
  #   receipt.send("#{_event}!") if _event.present?
  # end

  def after_create receipt
    receipt.moved_to_clearance_pending
    SelldoLeadUpdater.perform_async(receipt.user_id.to_s, {stage: 'payment_done', token_number: receipt.token_number.present?}) if (receipt.offline? || (receipt.online? && receipt.success? ))
  end

  def after_update receipt
    SelldoLeadUpdater.perform_async(receipt.user_id.to_s, {stage: 'payment_done', token_number: (receipt.token_number_changed? && receipt.token_number.present?)}) if (receipt.offline? || (receipt.online? && receipt.success? ))
  end
end
