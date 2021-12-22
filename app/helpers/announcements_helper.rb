module AnnouncementsHelper

  def category_icon_class category
    case category.to_s
    when 'new_launch'
      'fa-rocket fill-warning'
    when 'events'
      'fa-calendar-week fill-primary'
    when 'brokerage_alert'
      'fa-exclamation-triangle fill-danger'
    when 'general'
      'fa-calendar-week fill-primary'
    else
      'fa-calendar-week fill-primary'
    end
  end
  
  def custom_announcements_path
    current_user.buyer? ? buyer_announcements_path : admin_announcements_path
  end
end
