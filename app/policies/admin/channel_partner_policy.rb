class Admin::ChannelPartnerPolicy < ChannelPartnerPolicy
  # def export? def new? def edit? from ChannelPartnerPolicy
  def index?
    current_client.enable_channel_partners? && %w[superadmin admin cp_admin cp].include?(user.role)
  end

  def show?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def create?
    current_client.enable_channel_partners? && %w[admin channel_partner].include?(user.role)
  end

  def update?
    index?
  end

  def permitted_attributes(_params = {})
    attributes = [:name, :email, :phone, :rera_id, :title, :first_name, :region, :last_name, :street, :house_number, :city, :postal_code, :country, :mobile_phone, :email, :company_name, :pan_number, :gstin_number, :aadhaar, :rera_id, :manager_id, bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes, address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes]
    attributes += [:status] if user.present? && %w[superadmin admin cp_admin].include?(user.role) && record.status != 'active'
    attributes += [:status] if user.present? && ['cp'].include?(user.role) && record.status != 'active' && record.manager_id == user.id
    attributes += [:erp_id] if user.present? && %w[admin sales_admin].include?(user.role)
    attributes
  end
end
