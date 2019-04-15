class Buyer::UserKycPolicy < UserKycPolicy
  #def show? from UserKycPolicy
  def index?
    user.buyer?
  end

  def new?
    record.user_id == user.id if record.user_id.present? && user.buyer?
  end

  def show?
    index? && record.user_id == user.id
  end

  def create?
    new?
  end

  def edit?
    record.user_id == user.id if user.buyer?
  end

  def update?
    edit?
  end
end
