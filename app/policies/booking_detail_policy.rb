class BookingDetailPolicy < ApplicationPolicy
  # we allow only admin and user role people to access the update action for uploading files
  def update?
    %w[superadmin admin user].include?(user.role)
  end

  def permitted_attributes(_params = {})
    attributes = [:tds_doc]
    attributes += [:erp_id] if %w[admin sales_admin].include?(user.role)
    attributes += [:primary_user_kyc_id, :user_kyc_ids ]
    attributes
  end

  def checkout?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && eligible_user? && has_user_on_record? && available_for_user_group?
  end

  def enable_booking_with_kyc?
    current_client.enable_booking_with_kyc
  end

  private

  def only_single_unit_can_hold!
    return true if record.user.booking_details.where(status: 'hold').nin(_id: record.id).count.zero?
    @condition = 'hold_single_unit'
    false
  end

  def available_for_user_group?
    status = ['available', 'hold', 'user']
    status << 'employee' if record.user.role?('employee')
    status += ['employee', 'management'] if record.user.role?('management')

    return true if status.include?(record.project_unit.status)
    @condition = 'not_available_for_user_group'
    false
  end

  def is_buyer_booking_limit_exceed?
    return true if (record.user.allowed_bookings > record.user.booking_details.nin(status: %w[cancelled swapped]).count)
    @condition = "booking_limit_exceed"
    false
  end

  def buyer_kyc_booking_limit_exceed?
    return true if (record.user.unused_user_kyc_ids(record.id).present? || !(current_client.enable_booking_with_kyc) )
    @condition = "user_kyc_allowed_bookings"
    false
  end

  def eligible_user?
    enable_booking_with_kyc? ? only_for_kyc_added_users! : true
  end

end
