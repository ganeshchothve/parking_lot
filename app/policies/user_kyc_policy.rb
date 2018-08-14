class UserKycPolicy < ApplicationPolicy
  def index?(for_user=nil)
    if for_user.present?
      for_user.buyer?
    else
      true
    end
  end

  def new?
    if record.user_id.present? && user.buyer?
      record.user_id == user.id
    elsif record.user_id.present?
      record.user.buyer? && UserPolicy.new(user, record.user).edit?
    else
      false
    end
  end

  def edit?
    if user.buyer?
      record.user_id == user.id
    else
      record.user.buyer? && UserPolicy.new(user, record.user).edit?
    end
  end

  def create?
    new?
  end

  def export?
    UserPolicy.new(user, record.user).export?
  end

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :oci, :gstn, :anniversary, :nri, :poa, :customer_company_name, :existing_customer, :comments, :existing_customer_name, :existing_customer_project, :poa_details, :is_company, :education_qualification, :designation, :company_name, :poa_details_phone_no, correspondence_address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, permanent_address_attributes: AddressPolicy.new(user, Address.new).permitted_attributes, bank_detail_attributes: BankDetailPolicy.new(user, BankDetail.new).permitted_attributes, configurations:[], project_unit_ids: []]
    attributes
  end
end
