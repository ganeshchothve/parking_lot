class Admin::InvoicePolicy < InvoicePolicy
  def index?
    user.role.in?(%w(admin superadmin channel_partner billing_team))
  end

  def edit?
    update?
  end

  def update?
    user.role?('billing_team')
  end

  def change_state?
    user.role.in?(%w(channel_partner)) && record.draft? && record.may_raise?
  end

  def permitted_attributes(params = {})
    attributes = super
    case user.role.to_s
    when 'channel_partner'
      attributes += [:event] if record.draft? && record.may_raise?
    when 'billing_team'
      attributes += [:comments]
      attributes += [:event] if record.pending_approval?
    end
    attributes.uniq
  end
end
