class UserKycPolicy < ApplicationPolicy
  def index?(for_user=nil)
    if for_user.present?
      for_user.role?('user')
    else
      true
    end
  end

  def new?
    record.user_id.present? && record.user.role?('user')
  end

  def edit?
    if user.role?('user')
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
    attributes = [:name, :email, :phone, :dob, :pan_number, :aadhaar, :gstn, :anniversary, :nri, :poa, :company_name, :loan_required, :existing_customer, :comments]
    attributes
  end
end
