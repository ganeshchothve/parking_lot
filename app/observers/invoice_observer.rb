class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    resource = invoice.invoiceable
    if resource
      invoice.account_manager_id = resource.try(:account_manager_id)
      invoice.manager_id = resource&.manager_id
      if invoice.manager
        invoice.channel_partner_id = invoice.manager&.channel_partner_id
        invoice.cp_manager_id = invoice.manager&.manager_id
        invoice.cp_admin_id = invoice.cp_manager&.manager_id if invoice.cp_manager
      end
    end
    invoice.amount = invoice.calculate_amount
    invoice.gst_amount = invoice.calculate_gst_amount
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
