class Admin::InvoicePolicy < InvoicePolicy
  def index?
    user.role.in?(%w(admin superadmin channel_partner billing_team cp cp_admin)) && enable_incentive_module?(user)
  end

  def new?
    create?
  end

  def create?
    user.role?('channel_partner') && enable_incentive_module?(user) && incentive_calculation_type?("manual")
  end

  def edit?
    update?
  end

  def update?
    valid = user.role?('billing_team') && record.status.in?(%w(draft approved))
    valid ||= user.role?('channel_partner') && record.status.in?(%w(draft rejected))
    valid ||= user.role?('cp_admin') && record.pending_approval?
  end

  def update_gst?
    user.role.in?(%w(billing_team admin)) && record.status.in?(%w(draft pending_approval))
  end

  def change_state?
    user.role.in?(%w(channel_partner)) && record.aasm.events(permitted: true).map(&:name).include?(:raise)
  end

  def raise_invoice?
    change_state?
  end

  def generate_invoice?
    index? && record.approved?
  end

  def asset_create?
    user.role?('channel_partner') && !record.status.in?(%w(approved paid))
  end

  def asset_update?
    asset_create?
  end

  def incentive_calculation_type?(_type=nil)
    return true if current_client.incentive_calculation_type?(_type)
    false
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
      attributes += [:amount, :gst_amount, :number] if record.status.in?(%w(draft rejected))
      attributes += [:comments] if record.status.in?(%w(rejected draft))
      attributes += [:event] if record.rejected?
    when 'cp_admin'
      attributes += [:amount, :gst_amount, :rejection_reason, payment_adjustment_attributes: [:id, :absolute_value]] if record.status.in?(%w(pending_approval approved))
      attributes += [:rejection_reason] if record.status.in?(%w(pending_approval rejected))
      attributes += [:event]
    when 'billing_team'
      attributes += [:amount, :gst_amount] if record.status.in?(%w(draft pending_approval))
      attributes += [:rejection_reason] if record.status.in?(%w(draft pending_approval rejected))
      attributes += [cheque_detail_attributes: [:id, :total_amount, :payment_identifier, :issued_date, :issuing_bank, :issuing_bank_branch, :handover_date, :creator_id]] if record.status.in?(%w(approved paid))
      attributes += [:event] if record.status.in?(%w(draft approved))
    end
    attributes.uniq
  end
end
