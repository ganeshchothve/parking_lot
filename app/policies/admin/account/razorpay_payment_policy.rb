class Admin::Account::RazorpayPaymentPolicy < Admin::AccountPolicy
  def permitted_attributes
    super + %w(key secret)
  end
end
