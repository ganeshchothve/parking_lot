class Buyer::BookingDetailPolicy < BookingDetailPolicy

  def index?
    enable_actual_inventory?(user)
  end

  def booking?
    true
  end

  def show?
    true
  end

  def block?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && eligible_user? && only_for_hold! && is_buyer_booking_limit_exceed?
  end

  def hold?
    _role_based_check && enable_actual_inventory? && only_for_confirmed_user! && eligible_user? && only_single_unit_can_hold! && available_for_user_group? && is_buyer_booking_limit_exceed? && buyer_kyc_booking_limit_exceed?
  end

  def doc?
    true
  end

  private

  def only_for_hold!
    return true if ['hold'].include?(record.status)
    @condition = 'only_for_hold'
    false
  end

  def _role_based_check
    return true if record.user_id == user.id
    @condition = 'not_authorise_to_book_for_this_user'
    false
  end
end
