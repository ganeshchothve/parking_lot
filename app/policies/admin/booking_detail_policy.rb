class Admin::BookingDetailPolicy < BookingDetailPolicy

  def index?
    %w[admin superadmin sales sales_admin cp_admin gre channel_partner].include?(user.role) && enable_actual_inventory?(user)
  end

  def new?
    %w[admin superadmin sales sales_admin cp_admin gre channel_partner].include?(user.role) && eligible_user? && enable_actual_inventory?(user)
  end

  def create?
    return true if  is_buyer_booking_limit_exceed? && eligible_user? && enable_actual_inventory?(user)
    @condition = 'allowed_bookings'
    false
  end

  def booking?
    true
  end

  def edit?
    enable_actual_inventory?(user) && (!current_client.enable_booking_with_kyc? || record.user.user_kycs.present?)
  end

  def update?
    edit?
  end

  def tasks?
    eligible_users_for_tasks? && %w[cancelled swapped].exclude?(record.status)
  end

  def mis_report?
    true
  end

  def hold?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && eligible_user? && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed? && buyer_kyc_booking_limit_exceed?
  end

  def show_booking_link?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed?
  end

  def send_under_negotiation?
    hold?
  end

  def block?
    hold?
  end

  def doc?
    true
  end

  def status_chart?
    true
  end

  def send_booking_detail_form_notification?
    true
  end
  # def block?
  #   valid = enable_actual_inventory? && only_for_confirmed_user! && only_for_kyc_added_users! && ['hold'].include?(record.status)
  #   if !valid
  #     return
  #   end
  #   valid = (valid && record.user.allowed_bookings > record.user.booking_details.ne(status: 'cancelled').count)
  #   if !valid
  #     @condition = "allowed_bookings"
  #     return
  #   end
  #   _role_based_check
  # end

  def permitted_attributes
    attributes = super
    attributes += [:primary_user_kyc_id, :user_kyc_ids, :project_unit_id, :user_id ]
    if eligible_users_for_tasks?
      attributes += [tasks_attributes: TaskPolicy.new(user, Task.new).permitted_attributes]
    end
    attributes
  end

  private

  def eligible_users_for_tasks?
    return true if %w[admin channel_partner sales_admin sales].include?(user.role)
  end

  def need_unattached_booking_receipts_for_channel_partner
    if user.role?('channel_partner')
      return true if record.user.unattached_blocking_receipt(record.project_unit.blocking_amount).present?
      @condition = "blocking_amount_receipt"
      false
    else
      true
    end
  end

  def _role_based_check
    if %w[cp sales sales_admin cp_admin admin superadmin].include?(user.role)
      if record.hold?
        true
      elsif record.status.in?(BookingDetail::BOOKING_STAGES)
        @condition = 'booking_done'
        false
      else
        @condition = 'record_not_held'
        false
      end
    elsif (user.role?('channel_partner') && record.status == 'hold')
      return true if record.user.manager_id == user.id
      @condition = 'not_authorise_to_book_for_this_user'
      false
    else
      @condition = 'not_authorise_to_book_for_this_user'
      false
    end
  end

end
