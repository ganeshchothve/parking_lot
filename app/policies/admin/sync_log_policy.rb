class Admin::SyncLogPolicy < SyncLogPolicy
  include ApplicationHelper
  def index?
    user.booking_portal_client.external_api_integration? && %w[superadmin admin sales_admin].include?(user.role)
  end

  def resync?
    user.booking_portal_client.external_api_integration? && %w[superadmin admin sales_admin].include?(user.role)
  end

  def create?
    resync?
  end
end
