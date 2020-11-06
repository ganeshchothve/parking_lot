class ReceiptPolicy < ApplicationPolicy
  def resend_success?
    show?
  end

  def update_token_number?
    false
  end

  def edit_token_number?
    update_token_number?
  end

  def permitted_attributes params={}
    attributes = []
    attributes += [:payment_mode, :lead_id, :project_id] if record.new_record? || record.status == 'pending'
    if (record.user_id.present? && record.booking_detail_id.blank?) && %w[pending clearance_pending success available_for_refund].include?(record.status)
      attributes += [:booking_detail_id]
    end
    attributes += [:total_amount] if record.new_record? || %w[pending clearance_pending].include?(record.status)
    attributes
  end

  private

  def direct_payment?
    record.booking_detail_id.blank?
  end

  def eligible_user?
    direct_payment? ? enable_direct_payment? : enable_attached_payment?
  end

  def valid_booking_stages?
    return true if %w[hold under_negotiation scheme_approved blocked booked_tentative booked_confirmed].include?(record.booking_detail.status)

    @condition = 'not_allowed'
    false
  end

  def enable_direct_payment?
    return true if (current_client.enable_direct_payment?|| user.role?('channel_partner') ) && current_client.payment_gateway.present? && (enable_payment_with_kyc? ? record_user_kyc_ready? : true)

    @condition = 'enable_direct_payment'
    false
  end

  def enable_attached_payment?
    ((enable_booking_with_kyc? ? record_user_kyc_ready? : true) && valid_booking_stages?)
  end

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
    return true if (record.user.kyc_ready?)

    @condition = 'not_kyc_present'
    false
  end

  def enable_payment_with_kyc?
    current_client.enable_payment_with_kyc
  end

  def enable_booking_with_kyc?
    current_client.enable_booking_with_kyc
  end
end
