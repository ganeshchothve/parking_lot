class DashboardPolicy < Struct.new(:user, :dashboard)
  include ApplicationHelper

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

  def sales_board?
    user.role.in?(%w(team_lead))
  end

  def team_lead_dashboard?
    user.role.in?(current_client.team_lead_dashboard_access_roles)# || user.role?('team_lead')
  end

  def leaderboard?
    user.role.in?(%w[superadmin admin channel_partner cp_owner])# || user.role?('team_lead')
  end

  def dashboard_landing_page?
    true
  end
end
