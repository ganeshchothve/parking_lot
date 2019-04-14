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
    valid = confirmed_and_ready_user?
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

  def permitted_attributes(params = {})
    attributes = super
    attributes += [:project_unit_id] if user.buyer?
    attributes.uniq
  end

  private

  def confirmed_and_ready_user?
    user.confirmed? && user.kyc_ready?
  end
end
