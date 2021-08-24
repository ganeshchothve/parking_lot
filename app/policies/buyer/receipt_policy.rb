class Buyer::ReceiptPolicy < ReceiptPolicy
  def index?
    user.buyer?
  end

  def edit?
    false
  end

  def export?
    false
  end

  def show?
    record.user_id == user.id
  end

  def new?
    valid = confirmed_and_ready_user? && only_online_payment!
    valid &&= direct_payment? ? enable_direct_payment? : valid_booking_stages?
  end

  def create?
    new? && online_account_present?
  end

  def asset_create?
    user.id == record.user_id && confirmed_and_ready_user?
  end

  def update?
    edit?
  end

  def direct_payment?
    super && record.user_id == user.id
  end

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:token_type, :payment_type]
    attributes += [:booking_detail_id] if user.buyer?
    attributes.uniq
  end

  private

  def confirmed_and_ready_user?
    return true if user.confirmed? && eligible_user?
    @condition = 'user_not_confimred' if @condition.blank?
    false
  end

  def only_online_payment!
    return true if record.payment_mode == 'online'
    @condition = 'only_online_payment'
    false
  end
end
