class UserKycPolicy < ApplicationPolicy
  def index?
    record.user_id == user.id
  end

  def edit?
    record.user_id == user.id
  end

  def create?
    true
  end

  def update?
    record.user_id == user.id
  end

  def permitted_attributes params={}
    attributes = [:name, :email, :phone, :dob, :pan_number, :aadhaar, :gstn, :anniversary, :nri, :poa, :company_name, :loan_required, :existing_customer, :comments]
    attributes
  end
end
