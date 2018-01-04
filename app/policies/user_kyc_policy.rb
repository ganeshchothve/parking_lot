class UserKycPolicy < ApplicationPolicy
  def index?
    true
  end

  def new?
    true
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
