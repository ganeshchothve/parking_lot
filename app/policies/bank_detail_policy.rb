class BankDetailPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:name, :branch, :account_type, :ifsc_code, :account_number, :loan_required]
  end
end
