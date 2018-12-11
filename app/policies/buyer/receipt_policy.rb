class Buyer::ReceiptPolicy < ReceiptPolicy

  def index?
    user.byuer?
  end

  def export?
    false
  end

  def new?
    valid = confirmed_and_ready_user? && (record.project_unit_id.blank? || after_hold_payment? || after_blocked_payment? || after_under_negotiation_payment?)

    if record.project_unit_id.present?
      valid = valid && record.user.user_requests.where(project_unit_id: record.project_unit_id).where(status: "pending").blank?
    end

    valid = valid && current_client.payment_gateway.present? if record.payment_mode == "online"
    valid
  end

  private

  def confirmed_and_ready_user?
    user.confirmed? && user.kyc_ready?
  end
end
