class ChannelPartnerPolicy < ApplicationPolicy
  def index?
    user.role?('admin')
  end

  def export?
    ['admin'].include?(user.role)
  end

  def new?
    !user.present?
  end

  def edit?
    user.role?('admin')
  end

  def create?
    !user.present?
  end

  def update?
    user.role?('admin')
  end

  def permitted_attributes params={}
    attributes = [:name, :email, :phone, :rera_id, :location, :title, :first_name, :region, :last_name, :street, :house_number, :city, :postal_code, :country, :mobile_phone, :email, :company_name, :pan_no, :gstin_no, :aadhaar_no, :rera_id, :bank_name, :bank_beneficiary_account_no, :bank_account_type, :bank_address, :bank_city, :bank_postal_Code, :bank_region, :bank_country, :bank_ifsc_code, :pan_card_doc, :bank_check_doc, :aadhaar_card_doc]
    attributes += [:status] if user.present? && user.role?('admin')
    attributes
  end
end
