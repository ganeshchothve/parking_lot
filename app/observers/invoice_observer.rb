class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    invoice.amount = invoice.calculate_amount
    invoice.net_amount = invoice.calculate_net_amount

    _event = invoice.event.to_s
    invoice.event = nil
    if _event.present? && (invoice.aasm.current_state.to_s != _event.to_s)
      if invoice.send("may_#{_event.to_s}?")
        invoice.aasm.fire!(_event.to_sym)
      else
        invoice.errors.add(:status, 'transition is invalid')
      end
    end

    invoice.channel_partner_id = invoice.manager&.channel_partner_id if invoice.manager && invoice.channel_partner_id.blank?
  end

  def before_save invoice
    # Adjust net amount according to gst amount & adjustment input by channel partner & billing team.
    if (invoice.changed & %w(amount gst_amount)).present? || invoice.payment_adjustment.try(:absolute_value_changed?) || (invoice.incentive_deduction.present? && invoice.incentive_deduction.approved? && invoice.incentive_deduction.amount_changed?)
      invoice.net_amount = invoice.calculate_net_amount
    end
  end
end
