module AccountHelper
  def selected_account project_unit = nil
    if project_unit == nil
        Account::RazorpayPayment.find_by(by_default: true)
    else 
      project_tower = project_unit.project_tower
      towers = Array.new
      not_available_units =ProjectUnit.not_in(:status => ['available','hold'])
      not_available_units.each do |unit|
        towers << unit.project_tower
      end
      if towers.uniq.include? project_tower
        project_tower.account
      else
        Account::RazorpayPayment.find_by(by_default: true)
      end
      # BookingDetail.each do |booking_detail|
      #   towers << booking_detail.project_unit.project_tower
      # end
      # if towers.uniq.include? project_tower
      #   project_tower.account
      # else
      #   Account::RazorpayPayment.find_by(by_default: true)
      # end
    end
  end

  def set_up_account project_unit = nil
    account = selected_account(@project_unit)
    debugger
    Razorpay.setup(account.key, account.secret) 
  end
end