class Admin::SyncLogsController < AdminController
  include SyncLogsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  before_action :set_sync_reference, only: :resync
  # def apply_policy_scope, def resync, def set_sync_reference from SyncLogsConcern

  def index
    @sync_logs = SyncLog.build_criteria(params).order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  private

  def authorize_resource
    authorize [:admin, SyncLog]
  end
end
