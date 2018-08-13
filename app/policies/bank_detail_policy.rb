class BankDetailPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :name, :branch, :account_type, :ifsc_code, :account_number, :loan_required, :_destroy]
  end
end
