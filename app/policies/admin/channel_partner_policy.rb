class Admin::ChannelPartnerPolicy < ChannelPartnerPolicy
  # def export? def new? def edit? from ChannelPartnerPolicy
  def index?
    user.booking_portal_client.enable_channel_partners? && %w[superadmin admin cp_admin cp].include?(user.role)
  end

  def show?
    valid = %w[superadmin admin cp_admin].include?(user.role)
    valid ||= (user.role.in?(%w(cp_owner channel_partner)) && user.channel_partner.present? && user.channel_partner.id.to_s == record.id.to_s)
  end

  def new?
    if user.present?
      user.booking_portal_client.enable_channel_partners?
    else
      record.booking_portal_client.enable_channel_partners?
    end
    #%w[cp_admin].include?(user.role)
  end

  def create?
    user.booking_portal_client.enable_channel_partners? && %w[channel_partner cp_owner].include?(user.role)
  end

  def update?
    valid = show?
    #valid = valid && ['inactive', 'rejected'].include?(record.status) if user.role.in?(%w(cp_owner channel_partner))
    valid
  end

  def edit?
    update?
  end

  def asset_form?
    update?
  end

  def change_state?
    ['inactive', 'rejected'].include?(record.status) && user.role.in?(%w(cp_owner channel_partner))# && record.may_submit_for_approval?
  end

  def new_channel_partner?
    user.role.in?(["admin","superadmin", "account_manager", "account_manager_head"])
  end

  def create_channel_partner?
    new_channel_partner?
  end

  def show_add_company_link?
    user.role.in?(%w(superadmin admin cp_admin)) & user.booking_portal_client.enable_channel_partners?
  end

  def new_company?
    show_add_company_link?
  end

  def create_company?
    new_company?
  end

  def permitted_attributes(_params = {})
    attributes = []
    if user.blank? || (user.present? && (%w[superadmin admin cp_admin account_manager_head account_manager].include?(user.role) || (['channel_partner', 'cp_owner'].include?(user.role) && record.id == user.channel_partner_id && ['inactive', 'rejected'].include?(record.status))))
      attributes += [:email, :phone, :first_name, :last_name, :company_name, :company_owner_name, :company_owner_phone, :pan_number, :gstin_number, :aadhaar, :rera_id, :manager_id, :team_size, :rera_applicable, :gst_applicable, :nri, :experience, :average_quarterly_business, :referral_code, :city, :company_logo, expertise: [], developers_worked_for: [], interested_services: [], regions: [], address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes]
    end
    if user.role.in?(%w(cp_owner channel_partner)) && record.new_record?
      attributes += [:primary_user_id]
    end

    if user.present? && ['channel_partner', 'cp_owner'].include?(user.role) && record.id == user.channel_partner_id && ['pending', 'active'].include?(record.status)
      attributes += [:title, :first_name, :last_name, :rera_id, :gstin_number, :rera_applicable, :gst_applicable, :experience, :average_quarterly_business, :team_size, expertise: [], developers_worked_for: []]
    end

    if user.present? && ['channel_partner', 'cp_owner'].include?(user.role)
      attributes += [:email, :phone, :first_name, :last_name, :company_name, :company_owner_name, :company_owner_phone, :pan_number, :gstin_number, :aadhaar, :rera_id, :manager_id, :team_size, :rera_applicable, :gst_applicable, :nri, :experience, :average_quarterly_business, :referral_code, :city, expertise: [], developers_worked_for: [], interested_services: [], regions: [], address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes]
    end

    attributes += [third_party_references_attributes: ThirdPartyReferencePolicy.new(user, ThirdPartyReference.new).permitted_attributes] if user.present?

    # attributes += [bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes]

    if record.present?
      attributes += [:internal_category] if user.present? && (%w[superadmin admin cp_admin].include?(user.role) || (['cp'].include?(user.role) && record.manager_id == user.id))
      attributes += [:event, :status_change_reason] if user.present? && %w[superadmin admin cp_admin sales_admin].include?(user.role)
      attributes += [:event, :status_change_reason] if user.present? && ['cp'].include?(user.role) && record.status != 'active' && record.manager_id == user.id
      attributes += [:event] if user.present? && ['channel_partner', 'cp_owner'].include?(user.role) && record.id == user.channel_partner_id && ['inactive', 'rejected'].include?(record.status)
    end
    attributes += [:erp_id] if user.present? && %w[admin sales_admin].include?(user.role)
    attributes.uniq
  end
end
