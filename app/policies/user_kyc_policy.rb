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

  def update?
    edit?
  end

  def permitted_attributes params={}
    attributes = [:salutation, :first_name, :last_name, :email, :phone, :dob, :pan_number, :aadhaar, :oci, :gstn, :anniversary, :nri, :poa, :company_name, :loan_required, :existing_customer, :comments, :existing_customer_name, :existing_customer_project, :bank_name, :poa_details, :is_company, :street, :house_number, :state, :city, :postal_code, :country, :pancard_photo, :adharcard_photo, project_unit_ids: []]
    attributes
  end
end
