module PaymentHelper
  def payment_mode_options
    if current_user.buyer?
      Receipt.available_payment_modes.select{|x| x[:id] == 'online'}.collect{|x| [x[:text], x[:id]]}
    elsif ['admin','sales','sales_admin'].include?(current_user.role)
      Receipt.available_payment_modes.collect{|x| [x[:text], x[:id]]}
    else
      Receipt.available_payment_modes.reject{|x| x[:id] == 'online'}.collect{|x| [x[:text], x[:id]]}
    end
  end
end
