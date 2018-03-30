class ReceiptObserver < Mongoid::Observer
  def before_create receipt
    project_unit = receipt.project_unit
    if project_unit.present?
      # order = receipt.user.receipts.count
      receipt.receipt_id = "ESE#{project_unit.project_tower_name[0]}#{project_unit.name.split("-").last.strip}-R#{receipt.order_id}"
    else
      receipt.receipt_id = "tmp-#{SecureRandom.hex}"
    end
  end

  def after_save receipt
    user = receipt.user
    project_unit = receipt.project_unit
    if receipt.receipt_id.starts_with?("tmp-") && receipt.project_unit_id_changed? && receipt.project_unit_id.present?
      project_unit = receipt.project_unit
      # order = receipt.user.receipts.count
      receipt.receipt_id = "ESE#{project_unit.project_tower_name[0]}#{project_unit.name.split("-").last.strip}-R#{receipt.order_id}"
    end
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
        # push data to SFDC about payments
        SFDC::ReceiptsPusher.execute(receipt)
        user = receipt.user
        unless user.save
          # TODO: notify us about this
        end
      end
    end

    # update project unit if a successful receipt is getting attached to a project_unit
    # update the user balance if receipt has no project unit
    if receipt.project_unit_id_changed? && receipt.project_unit_id_was.blank? && ['success', 'clearance_pending'].include?(receipt.status) && !receipt.status_changed?
      project_unit.process_payment!(receipt)
      unless user.save
        # TODO: notify us about this
      end
    end

    # Send email to customer
    if receipt.status_changed?
      if receipt.status == 'success'
        # TODO : Sell.Do Receipt
        mailer = ReceiptMailer.send_success(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
        message = "Dear #{user.name}, your payment of Rs. #{receipt.total_amount} for unit #{project_unit.name} was successful (##{receipt.receipt_id}). To print your receipt visit #{user.dashboard_url}"
        if Rails.env.development?
          SMSWorker.new.perform(user.phone.to_s, message)
        else
          SMSWorker.perform_async(user.phone.to_s, message)
        end
      elsif receipt.status == 'failed'
        # TODO : Sell.Do Receipt
        mailer = ReceiptMailer.send_failure(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
        message = "Dear #{user.name}, your payment of Rs. #{receipt.total_amount} for unit #{project_unit.name} has failed (##{receipt.receipt_id})."
        if Rails.env.development?
          SMSWorker.new.perform(user.phone.to_s, message)
        else
          SMSWorker.perform_async(user.phone.to_s, message)
        end
      elsif receipt.status == 'clearance_pending'
        mailer = ReceiptMailer.send_clearance_pending(receipt.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
        message = "Dear #{user.name}, your payment of Rs. #{receipt.total_amount} for unit #{project_unit.name} is under 'Pending Clearance' (##{receipt.receipt_id}). To print your receipt visit #{user.dashboard_url}"
        if Rails.env.development?
          SMSWorker.new.perform(user.phone.to_s, message)
        else
          SMSWorker.perform_async(user.phone.to_s, message)
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
      message = "Dear #{user.name}, your payment of Rs. #{receipt.total_amount} has been received."
      if Rails.env.development?
        SMSWorker.new.perform(user.phone.to_s, message)
      else
        SMSWorker.perform_async(user.phone.to_s, message)
      end
    end
  end

  def before_save receipt
    if receipt.status_changed? && receipt.status == 'success' && receipt.processed_on.blank?
      receipt.processed_on = Date.today
    end
  end
end
