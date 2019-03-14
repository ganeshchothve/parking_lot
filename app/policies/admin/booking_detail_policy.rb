class Admin::BookingDetailPolicy < BookingDetailPolicy
  
  def booking?
    true
  end
  def mis_report?
    true
  end
end
