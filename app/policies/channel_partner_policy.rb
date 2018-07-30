class ChannelPartnerPolicy < ApplicationPolicy
  def index?
    user.role?('admin') || user.role?('superadmin')
  end

  def export?
    ['superadmin', 'admin'].include?(user.role)
  end

  def new?
    !user.present?
  end

  def edit?
    user.role?('admin') || user.role?('superadmin')
  end

  def create?
    !user.present?
  end

  def update?
    user.role?('admin') || user.role?('superadmin')
  end

  def permitted_attributes params={}
    attributes = [:name, :email, :phone, :rera_id, :title, :first_name, :region, :last_name, :street, :house_number, :city, :postal_code, :country, :mobile_phone, :email, :company_name, :pan_number, :gstin_number, :aadhaar, :rera_id, bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes, address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes]
    attributes += [:status] if user.present? && (user.role?('admin') || user.role?('superadmin'))
    attributes
  end
end
