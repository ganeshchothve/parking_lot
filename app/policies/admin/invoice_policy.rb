class Admin::InvoicePolicy < InvoicePolicy
  def index?
    out = false
    out = (user.role.in?(%w(admin superadmin channel_partner billing_team cp cp_admin)) && enable_incentive_module?(user))
    out =  true if user.role.in?(%w(account_manager))
    out 
  end

  def new?
    create?
  end

  def create?
    user.role.in?(%w(channel_partner admin billing_team)) && enable_incentive_module?(user) && incentive_calculation_type?("manual")
  end

  def edit?
    update?
  end

  def update?
    valid = user.role?('billing_team') && record.status.in?(%w(approved tax_invoice_raised paid pending_approval))
    valid ||= user.role?('channel_partner') && record.status.in?(%w(draft rejected))
    valid ||= user.role?('cp_admin') && record.pending_approval?
    valid ||= user.role?('admin') && record.status.in?(%w(draft rejected approved pending_approval))
  end

  def update_gst?
    user.role.in?(%w(billing_team admin)) && record.status.in?(%w(raised pending_approval))
  end

  def change_state?
    user.role.in?(%w(channel_partner admin billing_team)) #&& record.aasm.events(permitted: true).map(&:name).include?(:raise)
  end

  def raise_invoice?
    change_state?
  end

  def new_send_invoice_to_poc?
    user.role.in?(%w(billing_team)) && record.status.in?(%w(raised))
  end

  def send_invoice_to_poc?
    new_send_invoice_to_poc?
  end

  def generate_invoice?
    index? && record.approved? && !user.role?('billing_team')
  end

  def asset_create?
    user.role.in?(%w(channel_partner admin)) && !record.status.in?(%w(approved paid))
  end

  def asset_update?
    asset_create?
  end

  def incentive_calculation_type?(_type=nil)
    return true if current_client.incentive_calculation_type?(_type)
    false
  end

  def export?
    %w[superadmin admin sales_admin crm cp_admin billing_team cp].include?(user.role)
  end

  def permitted_attributes(params = {})
    attributes = super
    #case user.role.to_s
    #when 'channel_partner'
    #  attributes += [:comments]
    #  attributes += [:event, :gst_amount] if record.aasm.events(permitted: true).map(&:name).include?(:raise)
    #when 'billing_team'
    #  attributes += [:rejection_reason, cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id], payment_adjustment_attributes: [:id, :absolute_value]] unless record.status.in?(%w(approved rejected))
    #  attributes += [:event, :gst_amount] if record.pending_approval?
    #end
    case user.role.to_s
    when 'channel_partner'
      if record.status.in?(%w(draft rejected))
        attributes += [:number, :gst_amount, :comments, :event]
        attributes += [:amount, :agreement_amount] if record.manual?
      end
    when 'cp_admin'
      attributes += [:amount, :agreement_amount, :gst_amount, :rejection_reason, payment_adjustment_attributes: [:id, :absolute_value]] if record.status.in?(%w(pending_approval approved))
      attributes += [:rejection_reason] if record.status.in?(%w(pending_approval rejected))
      attributes += [:event]
    when 'admin'
      attributes += [:amount, :agreement_amount, :gst_amount, :rejection_reason, payment_adjustment_attributes: [:id, :absolute_value]] if record.status.in?(%w(pending_approval approved draft))
      attributes += [:rejection_reason] if record.status.in?(%w(pending_approval rejected draft))
      attributes += [cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id]] if record.status.in?(%w(approved paid))
      attributes += [:event]
    when 'billing_team'
      attributes += [:number, :gst_slab, :amount, :gst_amount, :agreement_amount] if record.status.in?(%w(draft))
      # attributes += [:amount, :gst_amount] if record.status.in?(%w(raised pending_approval))
      attributes += [:rejection_reason] if record.status.in?(%w(raised pending_approval rejected))
      attributes += [cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id]] if record.status.in?(%w(approved paid tax_invoice_raised))
      attributes += [:event] if record.status.in?(%w(draft raised approved tax_invoice_raised pending_approval))
    end
    attributes.uniq
  end
end
