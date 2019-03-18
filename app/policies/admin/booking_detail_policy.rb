class Admin::BookingDetailPolicy < BookingDetailPolicy
  
  def booking?
    true
  end

  def mis_report?
    true
  end

  def send_under_negotiation?
    true
  end
end
