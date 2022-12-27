class Admin::ReceiptPolicy < ReceiptPolicy
  # def edit_token_number? from ReceiptPolicy

  def index?
    if current_client.real_estate?
      out = !user.buyer? && (enable_actual_inventory?(user) || enable_direct_payment?)
      out = out && user.active_channel_partner? && !user.booking_portal_client.launchpad_portal && (user.booking_portal_client.enable_leads? || user.booking_portal_client.enable_site_visit?)
    else
      false
    end
  end

  def export?
    unless marketplace_client?
      %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
    else
      %w[superadmin admin].include?(user.role)
    end
  end

  def new?
    valid = record.user.present? && record.user.buyer? && confirmed_and_ready_user? && user.active_channel_partner? && record.lead&.project&.is_active? && !user.booking_portal_client.launchpad_portal
    # if is_assigned_lead?
    #   valid = valid && is_lead_accepted?
    # end
    valid
  end

  def create?
    if is_this_lost_receipt?
      lost_receipt?
    else
      new? && online_account_present? && user.active_channel_partner?
    end
  end

  def asset_create?
    confirmed_and_ready_user? && user.active_channel_partner?
  end

  def asset_update?
    asset_create?
  end

  def edit?
    return false if record.success? && record.booking_detail_id.present?

    valid = record.success? && record.booking_detail_id.blank?
    valid ||= (%w[pending clearance_pending available_for_refund].include?(record.status) && %w[superadmin admin crm sales_admin].include?(user.role))
    valid ||= (user.role?('channel_partner') && record.pending?)
    valid && user.active_channel_partner? && !user.booking_portal_client.launchpad_portal
  end

  def update?
    edit?
  end

  def update_token_number?
    %w[admin superadmin gre sales sales_admin].include?(user.role) && new?
  end

  def resend_success?
    show?
  end

  def lost_receipt?
    new? && only_superadmin?
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:payment_type]
    attributes += [:token_type] if record.direct_payment?
    attributes += [:booking_detail_id] if user.role?('channel_partner')
    if !user.buyer? && (record.new_record? || %w[pending clearance_pending].include?(record.status))
      attributes += %i[issued_date issuing_bank issuing_bank_branch payment_identifier]
    end
    attributes += %i[account_number payment_identifier] if user.role == 'superadmin' && record.payment_mode == 'online'
    if %w[sales sales_admin].include?(user.role) && %w[pending clearance_pending].include?(record.status)
      attributes += [:event]
    end
    if %w[admin crm superadmin sales_admin].include?(user.role)
      attributes += [:event] unless record.status.in?(%w(success))
      if record.persisted? && record.clearance_pending?
        attributes += %i[processed_on comments tracking_id]
      end
    end
    attributes += [:erp_id] if %w[admin sales_admin].include?(user.role)
    attributes += [:token_number] if %w[admin superadmin sales_admin sales gre].include?(user.role)
    attributes += [:time_slot_id] if record.persisted?
    attributes.uniq
  end

  private

  def confirmed_and_ready_user?
    record_user_is_present? && record_user_confirmed? && eligible_user?
  end

  def is_this_lost_receipt?
    record.new_record? && record.payment_identifier? && record.payment_mode == 'online'
  end

  def only_superadmin?
    return true if user.role?('superadmin')
    @condition = 'only_superadmin'
    false
  end

  def is_assigned_lead?
    if user.role?(:sales) && record.lead.is_a?(Lead)
      Lead.where(id: record.lead.id, closing_manager_id: user.id).in(customer_status: %w(engaged)).first.present?
    else
      false
    end
  end

  def is_lead_accepted?
    if user.role?(:sales) && record.lead.is_a?(Lead)
      record.lead.accepted_by_sales?
    else
      false
    end
  end
end
