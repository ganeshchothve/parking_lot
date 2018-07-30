class ReceiptPolicy < ApplicationPolicy
  def index?(for_user=nil)
    if for_user.present?
      for_user.buyer?
    else
      true
    end
  end

  def export?
    ['superadmin', 'admin', 'crm', 'sales', 'cp'].include?(user.role)
  end

  def new?
    if user.buyer?
      user.kyc_ready? && (record.project_unit_id.blank? || after_hold_payment?) && user.confirmed?
    else
      record.user_id.present? && record.user.kyc_ready? && (record.project_unit_id.blank? || after_hold_payment?) &&  record.user.confirmed?
    end
  end

  def direct?
    new?
  end

  def create?
    new?
  end

  def edit?
    !user.buyer? && (((user.role?('superadmin') || user.role?('admin') || user.role?('crm') || user.role?('sales')) && ['pending', 'clearance_pending'].include?(record.status)) || (user.role?('channel_partner') && record.status == 'pending'))
  end

  def update?
    edit?
  end

  def after_hold_payment?
    project_unit = record.project_unit
    unit_user = project_unit.user

    valid = project_unit.present? && project_unit.user_based_status(unit_user) == 'booked'

    if user.buyer?
      valid = valid && user.id == unit_user.id
    end
    valid
  end

  def permitted_attributes params={}
    attributes = []
    if record.new_record? || record.status == 'pending'
      attributes += [:payment_mode]
    end
    if user.buyer? || user.role?('channel_partner') || (record.user_id.present? && record.user.project_unit_ids.present?) && record.status == 'pending'
      attributes += [:project_unit_id]
    end
    if !user.buyer? && record.user_id.present? && record.status == 'pending'
      attributes += [:reference_project_unit_id]
    end
    if record.new_record? || record.status == 'pending'
      attributes += [:total_amount]
    end
    if !user.buyer? && (record.new_record? || record.status == 'pending')
      attributes += [:issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier]
    end
    if user.role?('admin') || user.role?('crm') || user.role?('sales')
      attributes += [:status]
      if record.persisted? && record.status == 'clearance_pending'
        attributes += [:processed_on, :comments, :tracking_id]
      end
    end
    attributes
  end
end
