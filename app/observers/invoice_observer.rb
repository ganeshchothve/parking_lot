class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    resource = invoice.invoiceable
    if resource
      invoice.account_manager_id = resource.try(:account_manager_id)
      invoice.manager_id = resource&.invoiceable_manager&.id if resource.manager_id.blank?
      if invoice.manager
        invoice.channel_partner_id = invoice.manager&.channel_partner_id
        invoice.cp_manager_id = invoice.manager&.manager_id
        invoice.cp_admin_id = invoice.cp_manager&.manager_id if invoice.cp_manager
      end
    end

    _event = invoice.event.to_s
    invoice.event = nil
    if _event.present? && (invoice.aasm.current_state.to_s != _event.to_s) && invoice.persisted?
      if invoice.send("may_#{_event.to_s}?")
        invoice.aasm.fire!(_event.to_sym)
      else
        invoice.errors.add(:status, 'transition is invalid')
      end
    end

    invoice.gst_amount = invoice.calculate_gst_amount
    invoice.net_amount = invoice.calculate_net_amount
  end

  def after_create invoice
    invoice.move_manual_invoice_to_draft
  end

  def after_save invoice
    # invoice generated set to trueif invoice.invoiceable.present?
    if invoice.invoiceable.present?
      if invoice.invoiceable.invoices.nin(status: ['rejected', 'tentative']).count > 0
        invoice.invoiceable.set(incentive_generated: true)
      else
        # invoice rejected set to false
        invoice.invoiceable.set(incentive_generated: false)
      end


      if invoice.status.in?(["tentative", "rejected"])
        invoice.change_status("draft") if invoice.invoiceable.draft_incentive_eligible?(invoice.category)
      end

    end
  end
end
