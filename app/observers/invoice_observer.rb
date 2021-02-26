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
    # Adjust net amount according to gst amount & adjustment input by channel partner & billing team.
    if (invoice.changed & %w(amount gst_amount)).present? || invoice.payment_adjustment.try(:absolute_value_changed?) || (invoice.incentive_deduction.present? && invoice.incentive_deduction.approved? && invoice.incentive_deduction.amount_changed?)
      invoice.net_amount = invoice.calculate_net_amount
    end
  end
end
