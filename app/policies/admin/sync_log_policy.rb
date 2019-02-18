class Admin::SyncLogPolicy < SyncLogPolicy
  include ApplicationHelper
  def index?
    true
  end

  def resync?
    %w[superadmin admin sales_admin].include?(user.role) && (current_client.selldo_form_id.present? && current_client.selldo_client_id.present?)
  end
end
