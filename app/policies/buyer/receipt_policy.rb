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
    valid = confirmed_and_ready_user? && (record.project_unit_id.blank? || after_hold_payment? || after_blocked_payment? || after_under_negotiation_payment?)

    if record.project_unit_id.present?
      valid = valid && record.user.user_requests.where(project_unit_id: record.project_unit_id).where(status: "pending").blank?
    end

    valid = valid && current_client.payment_gateway.present? if record.payment_mode == "online"
    valid
  end

  def create?
    new?
  end

  def asset_create?
    user.id == record.user_id && confirmed_and_ready_user?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = super
    attributes += [:project_unit_id] if user.buyer?
    attributes.uniq
  end

  private

  def confirmed_and_ready_user?
    user.confirmed? && user.kyc_ready?
  end
end
