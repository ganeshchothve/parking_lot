class Admin::ChannelPartnerPolicy < ChannelPartnerPolicy
  # def export? def new? def edit? from ChannelPartnerPolicy
  def index?
    current_client.enable_channel_partners? && %w[superadmin admin cp_admin cp].include?(user.role)
  end

  def show?
    valid = %w[superadmin admin cp_admin].include?(user.role)
    valid ||= (user.role == 'channel_partner' && user.associated_channel_partner.present? && user.associated_channel_partner.id.to_s == record.id.to_s)
  end

  def new?
    %w[cp_admin].include?(user.role)
  end

  def create?
    current_client.enable_channel_partners? && %w[channel_partner].include?(user.role)
  end

  def update?
    valid = show?
    #valid = valid && ['inactive', 'rejected'].include?(record.status) if user.role == 'channel_partner'
    valid
  end

  def edit?
    update?
  end

  def asset_form?
    update?
  end

  def change_state?
    ['inactive', 'rejected'].include?(record.status) && user.role == 'channel_partner'# && record.may_submit_for_approval?
  end

  def permitted_attributes(_params = {})
    attributes = []
    if user.blank? || (user.present? && (%w[superadmin admin cp_admin].include?(user.role) || (['channel_partner'].include?(user.role) && record.associated_user_id == user.id && ['inactive', 'rejected'].include?(record.status))))
      attributes += [:name, :email, :phone, :title, :first_name, :region, :last_name, :company_name, :company_owner_name, :company_owner_phone, :pan_number, :gstin_number, :aadhaar, :rera_id, :manager_id, :team_size, :rera_applicable, :gst_applicable, :nri, :experience, :average_quarterly_business, :referral_code, expertise: [], developers_worked_for: [], interested_services: [], address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes]
    end

    if user.present? && ['channel_partner'].include?(user.role) && record.associated_user_id == user.id && ['pending', 'active'].include?(record.status)
      attributes += [:title, :first_name, :last_name, :rera_id, :gstin_number, :rera_applicable, :gst_applicable, :experience, :average_quarterly_business, :team_size, expertise: [], developers_worked_for: []]
    end

    attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes] if user.present?

    # attributes += [bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes]

    if record.associated_user && record.associated_user.confirmed?
      attributes += [:event, :status_change_reason] if user.present? && %w[superadmin admin cp_admin sales_admin].include?(user.role)
      attributes += [:event, :status_change_reason] if user.present? && ['cp'].include?(user.role) && record.status != 'active' && record.manager_id == user.id
      attributes += [:event] if user.present? && ['channel_partner'].include?(user.role) && record.associated_user_id == user.id && ['inactive', 'rejected'].include?(record.status)
    end
    attributes += [:erp_id] if user.present? && %w[admin sales_admin].include?(user.role)
    attributes.uniq
  end
end
