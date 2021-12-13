module AnnouncementsHelper
  def custom_announcements_path
    current_user.buyer? ? buyer_announcements_path : admin_announcements_path
  end
end
