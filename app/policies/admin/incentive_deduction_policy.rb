class Admin::IncentiveDeductionPolicy < IncentiveDeductionPolicy
  def index?
    user.role.in?(%w(admin superadmin channel_partner billing_team cp_admin))
  end

  def new?
    create?
  end

  def create?
    user.role.in?(%w(cp_admin admin)) && !record.invoice.status.in?(%w(approved rejected)) && IncentiveDeduction.where(booking_portal_client_id: record.booking_portal_client_id, invoice_id: record.invoice_id, status: { '$ne': 'rejected' }).blank?
  end

  def edit?
    update?
  end

  def update?
    user.role.in?(%w(cp_admin admin)) && record.status.in?(%w(draft pending_approval))
  end

  def change_state?
    user.role.in?(%w(cp_admin billing_team admin)) && record.pending_approval?
  end

  def asset_create?
    user.role.in?(%w(cp_admin admin)) && record.status.in?(%w(draft pending_approval))
  end

  def permitted_attributes(params = {})
    attributes = super
    case user.role.to_s
    when 'cp_admin', 'admin'
      attributes += [:comments]
      attributes += [:amount] if record.new_record? && !record.invoice.status.in?(%w(approved rejected))
      attributes += [:event] if record.pending_approval?
    when 'billing_team'
      attributes += [:event] if record.pending_approval?
    end
    attributes.uniq
  end
end
