class Admin::SyncLogPolicy < SyncLogPolicy
  include ApplicationHelper
  def index?
    current_client.external_api_integration? && %w[superadmin admin sales_admin].include?(user.role)
  end

  def resync?
    current_client.external_api_integration? && %w[superadmin admin sales_admin].include?(user.role)
  end

  def create?
    resync?
  end
end
