class Admin::ReceiptPolicy < ReceiptPolicy
  def index?
    !user.buyer?
  end

  def export?
    %w[superadmin admin sales_admin crm].include?(user.role)
  end

  def new?
    valid = confirmed_and_ready_user?
    valid &&= direct_payment? ? (enable_direct_payment? || user.role?('channel_partner')) : valid_booking_stages?
  end

  def create?
    new? && online_account_present?
  end

  def asset_create?
    confirmed_and_ready_user?
  end

  def edit?
    return false if record.status == 'success' && record.project_unit_id.present?

    valid = record.status == 'success' && record.project_unit_id.blank?
    valid ||= (%w[pending clearance_pending available_for_refund].include?(record.status) && %w[admin crm sales_admin].include?(user.role))
    valid ||= (user.role?('channel_partner') && record.status == 'pending')
    valid
  end

  def update?
    edit?
  end

  def resend_success?
    show?
  end

  def lost_receipt?
    new? && user.role == 'superadmin'
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:booking_detail_id] if user.role?('channel_partner')
    if !user.buyer? && (record.new_record? || %w[pending clearance_pending].include?(record.status))
      attributes += %i[issued_date issuing_bank issuing_bank_branch payment_identifier]
    end
    attributes += %i[account_number payment_identifier] if user.role == 'superadmin' && record.payment_mode == 'online'
    if %w[sales sales_admin].include?(user.role) && %w[pending clearance_pending].include?(record.status)
      attributes += [:event]
    end
    if %w[admin crm superadmin sales_admin].include?(user.role)
      attributes += [:event]
      if record.persisted? && record.status == 'clearance_pending'
        attributes += %i[processed_on comments tracking_id]
      end
    end
    attributes += [:erp_id] if %w[admin sales_admin].include?(user.role)
    attributes.uniq
  end

  private

  def confirmed_and_ready_user?
    record_user_is_present? && record_user_confirmed? && record_user_kyc_ready?
  end
end
