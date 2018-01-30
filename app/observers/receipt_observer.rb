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
        mailer = ReceiptMailer.send_success(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
        if Rails.env.development?
          SMSWorker.new.perform("", "")
        else
          SMSWorker.perform_async(to: "", content: "")
        end
      elsif receipt.status == 'failed'
        mailer = ReceiptMailer.send_failure(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
        if Rails.env.development?
          SMSWorker.new.perform("", "")
        else
          SMSWorker.perform_async(to: "", content: "")
        end
      elsif receipt.status == 'clearance_pending'
        mailer = ReceiptMailer.send_clearance_pending(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
        if Rails.env.development?
          SMSWorker.new.perform("", "")
        else
          SMSWorker.perform_async(to: "", content: "")
        end
      end
    end

    # Send email to crm team if cheque non-online & pending
    if receipt.status == 'pending' && receipt.payment_mode != 'online'
      mailer = ReceiptMailer.send_pending_non_online(receipt.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      if Rails.env.development?
        SMSWorker.new.perform("", "")
      else
        SMSWorker.perform_async(to: "", content: "")
      end
    end
  end
end
