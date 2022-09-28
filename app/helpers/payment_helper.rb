module PaymentHelper
  def payment_mode_options
    if current_user.buyer?
      I18n.t("mongoid.attributes.receipt/payment_mode").select{|k,v| k.to_s == 'online'}.collect{|k,v| [v, k.to_s] }
    elsif ['admin','sales','sales_admin'].include?(current_user.role)
      I18n.t("mongoid.attributes.receipt/payment_mode").collect{|k,v| [v, k.to_s] }
    else
      I18n.t("mongoid.attributes.receipt/payment_mode").reject{|k,v| k.to_s == 'online'}.collect{|k,v| [v, k.to_s] }
    end
  end
end
