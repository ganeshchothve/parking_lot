class Admin::InvoicePolicy < InvoicePolicy
  def index?
    user.role.in?(%w(admin superadmin channel_partner billing_team cp_admin))
  end

  def edit?
    update?
  end

  def update?
    user.role?('billing_team')
  end

  def change_state?
    user.role.in?(%w(channel_partner)) && (record.aasm.events(permitted: true).map(&:name) & %i[raise re_raise]).present?
  end

  def re_raise?
    user.role.in?(%w(channel_partner)) && record.aasm.events(permitted: true).map(&:name).include?(:re_raise)
  end

  def permitted_attributes(params = {})
    attributes = super
    case user.role.to_s
    when 'channel_partner'
      attributes += [:comments]
      attributes += [:event] if (record.aasm.events(permitted: true).map(&:name) & %i[raise re_raise]).present?
    when 'billing_team'
      attributes += [:net_amount, :rejection_reason, cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id]] unless record.status.in?(%w(approved rejected))
      attributes += [:event] if record.pending_approval?
    end
    attributes.uniq
  end
end
