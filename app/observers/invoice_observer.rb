class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    booking_detail = invoice.booking_detail
    invoice.account_manager_id = booking_detail.account_manager_id
    invoice.manager_id = booking_detail.manager_id || booking_detail.channel_partner_id if (booking_detail.manager ||  booking_detail.channel_partner)
    invoice.channel_partner_id = invoice.manager.channel_partner_id if invoice.manager
    invoice.cp_manager_id = invoice.channel_partner&.manager_id if invoice.channel_partner
    invoice.cp_admin_id = invoice.cp_manager&.manager_id if invoice.cp_manager
    invoice.amount = invoice.calculate_amount
    invoice.net_amount = invoice.calculate_net_amount
  end

  def before_save invoice
    # Adjust net amount according to gst amount & adjustment input by channel partner & billing team.
    if (invoice.changed & %w(amount gst_amount)).present? || invoice.payment_adjustment.try(:absolute_value_changed?) || (invoice.incentive_deduction.present? && invoice.incentive_deduction.approved? && invoice.incentive_deduction.amount_changed?)
      invoice.net_amount = invoice.calculate_net_amount
    end
  end

  def after_save invoice
    _event = invoice.event.to_s
    invoice.event = nil
    if _event.present? && (invoice.aasm.current_state.to_s != _event.to_s) && invoice.persisted?
      if invoice.send("may_#{_event.to_s}?")
        invoice.aasm.fire!(_event.to_sym)
      else
        invoice.errors.add(:status, 'transition is invalid')
      end
    end
  end
end
