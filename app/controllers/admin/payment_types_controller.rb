class Admin::PaymentTypesController < AdminController

  def new
    @payment_type = PaymentType.new
    render layout: false
  end


end