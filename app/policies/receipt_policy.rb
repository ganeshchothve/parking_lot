class ReceiptPolicy < ApplicationPolicy
  def index?(for_user=nil)
    if for_user.present?
      for_user.role?('user')
    else
      true
    end
  end

  def export?
    ['admin', 'crm'].include?(user.role)
  end

  def new?
    if user.role?('user')
      user.kyc_ready? && (record.project_unit.blank? || booking_payment?) && user.confirmed?
    else
      record.user_id.present? && record.user.kyc_ready? && (record.project_unit.blank? || booking_payment?) &&  record.user.confirmed?
    end
  end

  def create?
    new?
  end

  def edit?
    !user.role?('user') && (((user.role?('admin') || user.role?('crm')) && ['pending', 'clearance_pending'].include?(record.status)) || (user.role?('channel_partner') && record.status == 'pending'))
  end

  def update?
    edit?
  end

  def booking_payment?
    project_unit = record.project_unit
    unit_user = project_unit.user

    valid = project_unit.present? && (project_unit.status == 'blocked' || project_unit.status == 'booked_tentative') && project_unit.pending_balance > 0 && unit_user.kyc_ready?

    if user.role?('user')
      valid = valid && user.id == unit_user.id
    end
    valid
  end

  def permitted_attributes params={}
    attributes = []
    if record.new_record? || record.status == 'pending'
      attributes += [:payment_mode]
    end
    if user.role?('user') || (record.user_id.present? && record.user.project_unit_ids.present?) && record.status == 'pending'
      attributes += [:project_unit_id]
    end
    if !user.role?('user') && record.user_id.present? && record.status == 'pending'
      attributes += [:reference_project_unit_id]
    end
    if record.new_record? || record.status == 'pending'
      attributes += [:total_amount]
    end
    if !user.role?('user') && (record.new_record? || record.status == 'pending')
      attributes += [:issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier]
    end
    if user.role?('admin') || user.role?('crm')
      attributes += [:status]
      if record.persisted? && record.status == 'clearance_pending'
        attributes += [:processed_on, :comments, :tracking_id]
      end
    end
    attributes
  end
end
