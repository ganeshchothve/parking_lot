class Buyer::UserKycPolicy < UserKycPolicy
  # def show? from UserKycPolicy

  def index?
    user.buyer?
  end

  def new?
    record.lead_id == user.selected_lead_id && user.buyer?
  end

  def show?
    index? && record.user_id == user.id
  end

  def create?
    new?
  end

  def edit?
    record.user_id == user.id && user.buyer?
  end

  def update?
    edit?
  end
end
