class Admin::SyncLogsController < AdminController
  include SyncLogsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  before_action :set_sync_reference, only: :resync
  # def apply_policy_scope from SyncLogsConcern

  def index
    @sync_logs = SyncLog.build_criteria(params).order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def resync
    record = @sync_log.resource
    @erp_models = ErpModel.where(resource_class: record.class, action_name: @sync_log.action, is_active: true)
    @erp_models.each do |erp|
      @sync_log.sync(erp, record)
    end
    redirect_back(fallback_location: root_path)
  end

  private

  def set_sync_reference
    @sync_log = SyncLog.where(id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, SyncLog]
  end
end
