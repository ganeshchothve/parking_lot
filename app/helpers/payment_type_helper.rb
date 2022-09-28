module PaymentTypeHelper

  def custom_payment_types_path
    current_user.buyer? ? '' : admin_payment_types_path
  end
end