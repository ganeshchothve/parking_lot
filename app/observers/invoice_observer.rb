class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    invoice.net_amount = invoice.amount.to_f if invoice.net_amount.blank? || invoice.net_amount.zero?

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

  def before_save invoice
    # Adjust net amount according to gst amount input by adding gst in net amount.
    if invoice.gst_amount_changed?
      new_gst = invoice.gst_amount.to_f
      if new_gst > 0
        invoice.net_amount = invoice.amount.to_f + new_gst
      elsif new_gst <= 0
        invoice.net_amount = invoice.amount.to_f
      end
    end
  end
end
