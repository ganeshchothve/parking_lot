class Buyer::SyncLogsController < BuyerController
  include SyncLogsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  before_action :set_sync_reference, only: :resync
  # def apply_policy_scope from SyncLogsConcern

  def index
    @sync_logs = SyncLog.where(user_id: current_user.id)
    @sync_logs = @sync_logs.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  private

  def authorize_resource
    authorize [:buyer, SyncLog]
  end
end
