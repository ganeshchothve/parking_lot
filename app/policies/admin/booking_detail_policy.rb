class Admin::BookingDetailPolicy < BookingDetailPolicy

  def index?
    %w[admin superadmin sales sales_admin cp_admin gre].include?(user.role)
  end
  
  def booking?
    true
  end

  def mis_report?
    true
  end
  
  def hold?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && only_for_kyc_added_users! && only_single_unit_can_hold! && available_for_user_group? && need_unattached_booking_receipts_for_channel_partner && is_buyer_booking_limit_exceed? && buyer_kyc_booking_limit_exceed?
  end

  def send_under_negotiation?
      hold?
  end
  def block? 
    hold?
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

  private

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
      true
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
