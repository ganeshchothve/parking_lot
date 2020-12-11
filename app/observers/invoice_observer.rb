class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    invoice.net_amount = invoice.amount if invoice.net_amount.blank?
    _event = invoice.event.to_s
    invoice.event = nil
    if _event.present? && (invoice.aasm.current_state.to_s != _event.to_s)
      if invoice.send("may_#{_event.to_s}?")
        invoice.aasm.fire!(_event.to_sym)
      else
        invoice.errors.add(:status, 'transition is invalid')
      end
    end
  end
end
