class Admin::ReceiptPolicy < ReceiptPolicy

  def index?
    !user.buyer?
  end

  def export?
    ['superadmin', 'admin', 'sales_admin', 'crm'].include?(user.role)
  end

  def new?
    valid = confirmed_and_ready_user?
    valid = valid && (record.project_unit_id.blank? || after_blocked_payment? || ((after_hold_payment? || after_under_negotiation_payment?) && editable_field?('event')))
    valid = valid && record.user.user_requests.where(project_unit_id: record.project_unit_id).where(status: "pending").blank?
    valid = valid && current_client.payment_gateway.present? if record.payment_mode == "online"
    valid
  end

  def create?
    new?
  end

  def edit?
    return false if record.status == "success" && record.project_unit_id.present?

    valid = record.status == "success" && record.project_unit_id.blank?
    valid ||= (['pending', 'clearance_pending', 'available_for_refund'].include?(record.status) && ['superadmin', 'admin', 'crm', 'sales_admin'].include?(user.role))
    valid ||= (user.role?('channel_partner') && record.status == 'pending')
    valid
  end

  def update?
    edit?
  end

  def resend_success?
    show?
  end

  private

  def confirmed_and_ready_user?
    record.user_id.present? && record.user.confirmed? && record.user.kyc_ready?
  end
end
