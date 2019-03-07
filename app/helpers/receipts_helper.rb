module ReceiptsHelper
  def user_local_time(time)
    time.in_time_zone(current_user.time_zone)
  end
end
