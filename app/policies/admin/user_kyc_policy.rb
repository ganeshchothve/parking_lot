class Admin::UserKycPolicy < UserKycPolicy
  def index?(for_user = nil)
    if current_client.real_estate?
      true if for_user.present? && for_user.buyer? || for_user.blank?
    else
      false
    end
  end

  def show?
    if current_client.real_estate?
      %w[superadmin admin sales_admin channel_partner].include?(user.role)
    else
      false
    end
  end

  def new?
    if current_client.real_estate?
      valid = record.lead&.project&.is_active?# && !marketplace_client?
      # if is_assigned_lead?
      #   valid = is_lead_accepted? && valid
      # end
      valid
    else
      false
    end
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

  def is_lead_accepted?
    if user.role?(:sales) && record.lead.is_a?(Lead)
      record.lead.accepted_by_sales?
    else
      false
    end
  end

  def is_assigned_lead?
    if user.role?(:sales) && record.lead.is_a?(Lead)
      Lead.where(id: record.lead.id, closing_manager_id: user.id).in(customer_status: %w(engaged)).first.present?
    else
      false
    end
  end
end
