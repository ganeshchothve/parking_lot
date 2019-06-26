class Admin::Account::CcAvenuePaymentPolicy < Admin::AccountPolicy
  def permitted_attributes
    super + %w(merchant_id working_key access_code)
  end
end
