class BankDetailPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :name, :branch, :account_type, :account_holder_name, :ifsc_code, :account_number, :loan_required, :loan_amount, :loan_sanction_days, :zip, :booking_portal_client_id, :_destroy]
  end
end
