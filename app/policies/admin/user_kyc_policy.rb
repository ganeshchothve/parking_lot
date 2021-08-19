class Admin::UserKycPolicy < UserKycPolicy
  def index?(for_user = nil)
    #true if for_user.present? && for_user.buyer? || for_user.blank?
    false
  end

  def show?
    %w[superadmin admin sales_admin channel_partner].include?(user.role)
  end

  def new?
    true #record.user.buyer?
  end

  def create?
    new?
  end

  def edit?
    true #record.user.buyer?
  end

  def update?
    edit?
  end

  def permitted_attributes(_params = {})
    attributes = super
    attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes] if %w[admin sales_admin].include?(user.role)
    attributes.uniq
  end
end
