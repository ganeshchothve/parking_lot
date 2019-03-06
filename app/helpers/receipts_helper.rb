module ReceiptsHelper
  def current_time(time)
    time.in_time_zone(current_user.time_zone)
  end
end
