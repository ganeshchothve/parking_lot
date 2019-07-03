class ReceiptObserver < Mongoid::Observer
  def before_validation(receipt)
    receipt.send(receipt.event) if receipt.event.present? && receipt.aasm.current_state.to_s != receipt.event.to_s
  end

  def before_save(receipt)
    receipt.receipt_id = receipt.generate_receipt_id
    if receipt.status_changed? && receipt.status == "success"
      receipt.assign!(:order_id) if receipt.order_id.blank?
    end
  end

  def after_save(receipt)
    # if receipt.status_changed?
    #   Notification::Receipt.new(receipt.id, receipt.changes).execute
    # end

    _event = receipt.event
    receipt.event = nil
    receipt.send("#{_event}!") if _event.present?
  end

  def after_create receipt
    SelldoLeadUpdater.perform_async(receipt.user_id.to_s, 'payment_done') if (receipt.payment_mode == 'offline' || (receipt.payment_mode == 'online' && receipt.success? ))
  end
  def after_update receipt
    SelldoLeadUpdater.perform_async(receipt.user_id.to_s, 'payment_done') if (receipt.payment_mode == 'offline' || (receipt.payment_mode == 'online' && receipt.success? ))
  end
end
