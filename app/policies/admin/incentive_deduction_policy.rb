class Admin::IncentiveDeductionPolicy < IncentiveDeductionPolicy
  def index?
    user.role.in?(%w(admin superadmin channel_partner billing_team cp_admin))
  end

  def new?
    create?
  end

  def create?
    user.role?('cp_admin') && !record.invoice.status.in?(%w(approved rejected)) && IncentiveDeduction.where(invoice_id: record.invoice_id, status: { '$ne': 'rejected' }).blank?
  end

  def edit?
    update?
  end

  def update?
    user.role.in?(%w(cp_admin)) && record.status.in?(%w(draft pending_approval))
  end

  def change_state?
    user.role.in?(%w(billing_team)) && record.pending_approval?
  end

  def asset_create?
    user.role?('cp_admin') && record.status.in?(%w(draft pending_approval))
  end

  def permitted_attributes(params = {})
    attributes = super
    case user.role.to_s
    when 'cp_admin'
      attributes += [:comments]
      attributes += [:amount] if record.new_record? && !record.invoice.status.in?(%w(approved rejected))
    when 'billing_team'
      attributes += [:event] if record.pending_approval?
    end
    attributes.uniq
  end
end
