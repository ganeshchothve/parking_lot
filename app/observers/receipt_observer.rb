class ReceiptObserver < Mongoid::Observer

  def before_validation receipt
    receipt.send(receipt.event) if receipt.event.present? && receipt.aasm.current_state.to_s != receipt.event.to_s 
  end

  def before_save receipt
    if receipt.status_changed? && receipt.status == 'success'
      receipt.processed_on = Date.today if receipt.processed_on.blank?
      receipt.assign!(:order_id) if receipt.order_id.blank?
    end
    receipt.receipt_id = receipt.generate_receipt_id
  end

  def after_save receipt
    user = receipt.user
    project_unit = receipt.project_unit
    if project_unit.present?
      project_unit.booking_detail.update(receipt_ids: project_unit.receipt_ids)
      project_unit.booking_detail.under_negotiation! if project_unit.booking_detail.aasm.current_state == :hold
    end

    # update project unit if a successful receipt is getting attached to a project_unit
    # update the user balance if receipt has no project unit
    if receipt.project_unit_id_changed? && receipt.project_unit_id_was.blank? && ['success', 'clearance_pending'].include?(receipt.status) && !receipt.status_changed?
      project_unit.process_payment!(receipt)
      unless user.save
        # TODO: notify us about this
      end
    end

    # update project unit if receipt status has changed
    if receipt.status_changed?
      Notification::Receipt.new(receipt.id, receipt.changes).execute
      project_unit = receipt.project_unit
      # if project_unit.present?
      #   status = if project_unit.status == "hold"
      #     ProjectUnitBookingService.new(project_unit.id).book
      #   else
      #     project_unit.process_payment!(receipt)
      #   end

      #   if status == true
      #   elsif receipt.status != 'clearance_pending'
      #     # TODO: send us and client team an error message. Escalate this.
      #   end
      # end

      # update user stats if receipt status is success
      if receipt.status == 'success'
        user = receipt.user
        unless user.save
          # TODO: notify us about this
        end
      end
    end
  end


end
