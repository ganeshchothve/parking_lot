class Admin::UserKycPolicy < UserKycPolicy
  def index?(for_user = nil)
    true if for_user.present? && for_user.buyer? || for_user.blank?
  end

  def show?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def new?
    record.user.buyer?
  end

  def create?
    new?
  end

  def edit?
    record.user.buyer?
  end

  def update?
    edit?
  end

  def permitted_attributes(_params = {})
    attributes = super
    attributes += [:erp_id] if %w[admin sales_admin].include?(user.role)
    attributes.uniq
  end
end
