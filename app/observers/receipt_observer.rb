class ReceiptObserver < Mongoid::Observer
  def after_save receipt
    user = receipt.user
    project_unit = receipt.project_unit

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
      project_unit = receipt.project_unit
      if project_unit.present?
        if project_unit.process_payment!(receipt)
        elsif receipt.status != 'clearance_pending'
          # TODO: send us and client team an error message. Escalate this.
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
  end

  def before_save receipt
    if receipt.status_changed? && receipt.status == 'success' && receipt.processed_on.blank?
      receipt.processed_on = Date.today
      receipt.assign!(:order_id) if receipt.order_id.blank?
    end
    if receipt.new_record? || receipt.receipt_id.downcase.include?("tmp-") && receipt.status_changed? && receipt.status != "pending"
      receipt.receipt_id = receipt.generate_receipt_id
    end
    receipt.send(receipt.event) if receipt.event.present?
  end
end
