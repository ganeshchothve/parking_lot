class ReceiptObserver < Mongoid::Observer
  def after_save receipt
    # update project unit if receipt status has changed
    if receipt.status_changed?
      project_unit = receipt.project_unit
      if project_unit.present?
        if project_unit.process_payment!(receipt)
        elsif receipt.status != 'clearance_pending'
          # TODO: send us and embassy team an error message. Escalate this.
        end
      end

      # update user stats if receipt status is success
      if receipt.status == 'success'
        user = receipt.user
        unless user.save
          # TODO: notify us about this
        end
      end
    end

    # update project unit if a successful receipt is getting attached to a project_unit
    # update the user balance if receipt has no project unit
    if receipt.project_unit_id_changed? && receipt.project_unit_id_was.blank? && ['success', 'clearance_pending'].include?(receipt.status) && !receipt.status_changed?
      user = receipt.user
      project_unit = receipt.project_unit
      project_unit.process_payment!(receipt)
      unless user.save
        # TODO: notify us about this
      end
    end

    # Send email to customer
    if receipt.status_changed?
      if receipt.status == 'success'
        ReceiptMailer.send_success(receipt.receipt_id).deliver_later
      elsif receipt.status == 'failed'
        ReceiptMailer.send_failure(receipt.receipt_id).deliver_later
      elsif receipt.status == 'clearance_pending'
        ReceiptMailer.send_clearance_pending(receipt.receipt_id).deliver_later
      end
    end
  end

  def after_create receipt
    if receipt.status == 'success'
      ReceiptMailer.send_success(receipt.receipt_id).deliver_later
    elsif receipt.status == 'clearance_pending'
      ReceiptMailer.send_clearance_pending(receipt.receipt_id).deliver_later
    end
  end
end
