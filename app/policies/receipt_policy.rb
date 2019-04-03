class ReceiptPolicy < ApplicationPolicy

  def resend_success?
    show?
  end

  def direct?
    current_client.enable_direct_payment? && new?
  end

  def after_hold_payment?
    project_unit = record.project_unit
    valid = project_unit.present? && project_unit.status == "hold"
    valid
  end

  def after_blocked_payment?
    record.project_unit.present? && record.project_unit.status != 'hold' && record.project_unit.user_based_status(record.user) == "booked"
  end

  def after_under_negotiation_payment?
    record.project_unit.present? && record.project_unit.status == 'under_negotiation'
  end

  def permitted_attributes params={}
    attributes = []
    attributes += [:payment_mode] if record.new_record? || record.status == 'pending'
    if (record.user_id.present? && record.user.project_unit_ids.present? && record.project_unit_id.blank?) && (['pending', 'clearance_pending', 'success', 'available_for_refund'].include?(record.status))
      attributes += [:booking_detail_id]
    end
    attributes += [:total_amount] if record.new_record? || ['pending', 'clearance_pending'].include?(record.status)
   #  attributes += [:account_number] if record.payment_mode == 'online'
    attributes
  end

  private

  def online_account_present?
    return true if record.payment_mode != 'online'
    return true if record.account.present?
    @condition = 'online_account_not_present'
    false
  end

  def record_user_is_present?
    return true if record.user_id.present?
    @condition = 'no_user_present'
    false
  end

  def record_user_confirmed?
    return true if record.user.confirmed?
    @condition = 'user_not_confimred'
    false
  end

  def record_user_kyc_ready?
    return true if record.user.kyc_ready?
    @condition = 'not_kyc_present'
    false
  end
end
