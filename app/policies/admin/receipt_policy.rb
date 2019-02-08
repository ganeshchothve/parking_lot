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
    new? && ['admin','sales','sales_admin', 'channel_partner'].include?(user.role)
  end

  def asset_create?
    confirmed_and_ready_user?
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

  def permitted_attributes params={}
    attributes = super
    attributes += [:project_unit_id] if user.role?('channel_partner')
    if !user.buyer? && (record.new_record? || ['pending', 'clearance_pending'].include?(record.status))
      attributes += [:issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier]
    end
    if ['sales', 'sales_admin'].include?(user.role) && %w[pending clearance_pending ].include?(record.status)
      attributes += [:event]
    end
    if ['admin', 'crm', 'superadmin', 'sales_admin'].include?(user.role)
      attributes += [:event]
      if record.persisted? && record.status == 'clearance_pending'
        attributes += [:processed_on, :comments, :tracking_id]
      end
    end
    attributes.uniq
  end

  private


  def confirmed_and_ready_user?
    record.user_id.present? && record.user.confirmed? && record.user.kyc_ready?
  end
end
