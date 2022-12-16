class DashboardPolicy < Struct.new(:user, :dashboard)
  include ApplicationHelper

  attr_reader :user, :current_client, :current_project, :current_domain

  def initialize(user_context, record)
    if user_context.is_a?(User)
      user = user_context
      @user = user
      @current_client = user.role?('superadmin') ? user.selected_client : user.booking_portal_client
      @current_project = nil
      @current_domain = nil
    else
      @user = user_context.user
      @current_client = user_context.current_client
      @current_project = user_context.current_project
      @current_domain = user_context.current_domain
    end
  end

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

  def gamify_unit_selection?
    true
  end

  def admin_dashboard?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def sales_board?
    user.role.in?(%w(team_lead)) && user.booking_portal_client.enable_site_visit?
  end

  def team_lead_dashboard?
    user.role.in?(user.booking_portal_client.team_lead_dashboard_access_roles) && user.booking_portal_client.enable_site_visit?# || user.role?('team_lead')
  end

  # def leaderboard?
  #   user.role.in?(%w[superadmin admin channel_partner cp_owner]) && current_client.enable_vis?# || user.role?('team_lead')
  # end

  # def dashboard_landing_page?
  #   leaderboard?
  # end

  def payout_dashboard?
    user.role.in?(%w[channel_partner cp_owner])
  end

  def show_upi_message?
    user.fund_accounts.count.zero? && !user.booking_portal_client.is_marketplace?
  end
end
