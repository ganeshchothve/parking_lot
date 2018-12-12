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
    if record.new_record? || record.status == 'pending'
      attributes += [:payment_mode]
    end

    if user.buyer? || user.role?('channel_partner') || (record.user_id.present? && record.user.project_unit_ids.present? && record.project_unit_id.blank?) && (['pending', 'clearance_pending', 'success', 'available_for_refund'].include?(record.status))
      attributes += [:project_unit_id]
    end
    attributes += [:total_amount] if record.new_record? || ['pending', 'clearance_pending'].include?(record.status)
    if !user.buyer? && (record.new_record? || ['pending', 'clearance_pending'].include?(record.status))
      attributes += [:issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier]
    end
    if ['sales', 'sales_admin'].include?(user.role) && (record.status == "pending" || record.status == "clearance_pending")
      attributes += [:event]
    end
    if ['admin', 'crm', 'superadmin', 'sales_admin'].include?(user.role)
      attributes += [:event]
      if record.persisted? && record.status == 'clearance_pending'
        attributes += [:processed_on, :comments, :tracking_id]
      end
    end
    attributes
  end
end
