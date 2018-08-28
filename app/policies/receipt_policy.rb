class ReceiptPolicy < ApplicationPolicy
  def index?(for_user=nil)
    if for_user.present?
      for_user.buyer?
    else
      true
    end
  end

  def export?
    ['superadmin', 'admin', 'sales_admin'].include?(user.role)
  end

  def new?
    if user.buyer?
      valid = user.kyc_ready? && user.confirmed? && (record.project_unit_id.blank? || after_hold_payment? || after_blocked_payment?)
    else
      valid = record.user_id.present? && record.user.kyc_ready? && record.user.confirmed?
      valid = valid && (record.project_unit_id.blank? || after_blocked_payment? || (after_hold_payment? && editable_field?('event')))
    end
    valid = valid && current_client.payment_gateway.present? if record.payment_mode == "online"
    valid
  end

  def direct?
    current_client.enable_direct_payment? && new?
  end

  def create?
    new?
  end

  def edit?
    !user.buyer? && (((user.role?('superadmin') || user.role?('admin') || user.role?('crm') || user.role?('sales')) && ['pending', 'clearance_pending', 'available_for_refund'].include?(record.status)) || (user.role?('channel_partner') && record.status == 'pending'))
  end

  def resend_success?
    show?
  end

  def update?
    edit?
  end

  def after_hold_payment?
    project_unit = record.project_unit
    valid = project_unit.present? && project_unit.status == "hold"
    valid
  end

  def after_blocked_payment?
    record.project_unit.present? && record.project_unit.status != 'hold' && record.project_unit.user_based_status(record.user) == "booked"
  end

  def permitted_attributes params={}
    attributes = []
    if record.new_record? || record.status == 'pending'
      attributes += [:payment_mode]
    end
    if user.buyer? || user.role?('channel_partner') || (record.user_id.present? && record.user.project_unit_ids.present?) && (record.status == 'pending' || record.status == 'available_for_refund')
      attributes += [:project_unit_id]
    end
    attributes += [:total_amount] if record.new_record? || ['pending', 'clearance_pending'].include?(record.status)
    if !user.buyer? && (record.new_record? || ['pending', 'clearance_pending'].include?(record.status))
      attributes += [:issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier]
    end
    if ['sales', 'sales_admin'].include?(user.role) && (record.status == "pending" || record.status == "clearance_pending")
      attributes += [:event]
    end
    if ['admin', 'crm', 'superadmin'].include?(user.role)
      attributes += [:event]
      if record.persisted? && record.status == 'clearance_pending'
        attributes += [:processed_on, :comments, :tracking_id]
      end
    end
    attributes
  end
end
