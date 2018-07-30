class UserKycPolicy < ApplicationPolicy
  def index?(for_user=nil)
    if for_user.present?
      for_user.buyer?
    else
      true
    end
  end

  def new?
    record.user_id.present? && record.user.buyer?
  end

  def edit?
    if user.buyer?
      record.user_id == user.id
    elsif user.role?('channel_partner')
      record.user.channel_partner_id == user.id
    else
      true
    end
  end

  def create?
    true
  end

  def export?
    ['admin', 'crm'].include?(user.role)
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :oci, :gstn, :anniversary, :nri, :poa, :customer_company_name, :existing_customer, :comments, :existing_customer_name, :existing_customer_project, :poa_details, :is_company, :education_qualification, :designation, :company_name, :poa_details_phone_no, correspondence_address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, permanent_address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes, project_unit_ids: []]
    attributes
  end
end
