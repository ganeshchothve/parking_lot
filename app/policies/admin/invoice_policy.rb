class Admin::InvoicePolicy < InvoicePolicy
  def index?
    out = false
    out = (user.role.in?(%w(admin superadmin channel_partner cp_owner billing_team cp cp_admin account_manager account_manager_head)) && enable_incentive_module?(user))
    out
  end

  def new?
    create?
  end

  def create?
    return false if record.project && !(record.project.is_active? && record.project&.invoicing_enabled?)
    user.role.in?(%w(channel_partner cp_owner admin superadmin billing_team)) && enable_incentive_module?(user) && incentive_calculation_type?("manual")
  end

  def edit?
    update?
  end

  def update?
    return false if record.project && !record.project.is_active?
    valid = user.role?('billing_team') && record.status.in?(%w(approved tax_invoice_raised pending_approval raised))
    # valid ||= user.role.in?(%w(channel_partner cp_owner)) && record.status.in?(%w(draft rejected))
    valid ||= user.role?('cp_admin') && record.pending_approval?
    valid ||= user.role.in?(%w(superadmin admin)) && record.status.in?(%w(draft rejected approved pending_approval raised))
    valid
  end

  def update_gst?
    return false if record.project && !record.project.is_active?
    user.role.in?(%w(billing_team admin)) && record.status.in?(%w(raised pending_approval))
  end

  def change_state?
    return false if record.project && !record.project.is_active?
    user.role.in?(%w(channel_partner cp_owner admin billing_team)) #&& record.aasm.events(permitted: true).map(&:name).include?(:raise)
  end

  def move_tentative_to_draft?
    user.role.in?(%w(admin billing_team)) && record.status == 'tentative'
  end

  def raise_invoice?
    change_state?
  end

  def new_send_invoice_to_poc?
    return false if record.project && !record.project.is_active?
    user.role.in?(%w(billing_team)) && record.status.in?(%w(raised))
  end

  def send_invoice_to_poc?
    new_send_invoice_to_poc?
  end

  def generate_invoice?
    return false if record.project && !record.project.is_active?
    index? && record.approved? && !user.role?('billing_team')
  end

  def asset_create?
    return false if record.project && !record.project.is_active?
    user.role.in?(%w(channel_partner cp_owner admin)) && !record.status.in?(%w(approved paid))
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
    #  attributes += [:event, :percentage_slab] :gst_slab, if record.aasm.events(permitted: true).map(&:name).include?(:raise)
    #when 'billing_team'
    #  attributes += [:rejection_reason, cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id], payment_adjustment_attributes: [:id, :absolute_value]] unless record.status.in?(%w(approved rejected))
    #  attributes += [:event, :percentage_slab] :gst_slab, if record.pending_approval?
    #end
    attributes += [:creator_id]
    case user.role.to_s
    when 'channel_partner', 'cp_owner'
      if record.status.in?(%w(draft rejected))
        attributes += [:number, :amount, :gst_slab, :comments]
        attributes += [:category] if record.new_record?
        attributes += [:agreement_amount] if record.manual? && record.invoiceable_type == 'BookingDetail'
      end
    when 'cp_admin'
      if record.status.in?(%w(pending_approval approved))
        attributes += [:brokerage_type, :payment_to, :amount, :gst_slab, :rejection_reason, payment_adjustment_attributes: [:id, :absolute_value]]
        attributes += [:category] if record.new_record?
        attributes += [:agreement_amount] if record.invoiceable_type == 'BookingDetail'
      end
      attributes += [:rejection_reason] if record.status.in?(%w(pending_approval rejected))
      attributes += [:event]
    when 'admin', 'superadmin'
      if record.status.in?(%w(pending_approval approved draft tentative))
        attributes += [:brokerage_type, :payment_to, :number, :amount, :gst_slab, :rejection_reason, payment_adjustment_attributes: [:id, :absolute_value]]
        attributes += [:category] if record.new_record?
        attributes += [:agreement_amount] if record.invoiceable_type == 'BookingDetail'
      end
      attributes += [:rejection_reason] if record.status.in?(%w(pending_approval rejected draft raised))
      #attributes += [cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id]] if record.status.in?(%w(approved paid))
      attributes += [:event]
    when 'billing_team'
      if record.status.in?(%w(tentative draft raised))
        attributes += [:brokerage_type, :payment_to, :number, :amount, :gst_slab]
        attributes += [:category] if record.new_record?
        attributes += [:agreement_amount] if record.invoiceable_type == 'BookingDetail' && record.category != 'spot_booking'
      end
      # attributes += [:amount, :percentage_slab] :gst_slab, if record.status.in?(%w(raised pending_approval))
      attributes += [:rejection_reason] if record.status.in?(%w(raised pending_approval rejected))
      #attributes += [cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id]] if record.status.in?(%w(approved paid tax_invoice_raised))
      attributes += [:event] if record.status.in?(%w(tentative draft raised approved tax_invoice_raised pending_approval))
    end
    attributes.uniq
  end
end
