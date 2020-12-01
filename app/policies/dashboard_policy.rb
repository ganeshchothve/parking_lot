class DashboardPolicy < Struct.new(:user, :dashboard)
  def index?
    true
  end

  def download_brochure?
    true
  end

  def faqs?
    true
  end

  def documents?
    user.active_channel_partner?
  end

  def rera?
    true
  end

  def tds_process?
    true
  end

  def terms_and_conditions?
    true
  end

  def gamify_unit_selection?
    true
  end

  def admin_dashboard?
    %w[superadmin admin sales_admin].include?(user.role)
  end
end
