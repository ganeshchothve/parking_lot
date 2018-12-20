class Admin::UserKycPolicy < UserKycPolicy
  def index?(for_user = nil)
    true if for_user.present? && for_user.buyer? || for_user.blank?
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
end
