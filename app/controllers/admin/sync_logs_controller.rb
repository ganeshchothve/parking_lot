class Admin::SyncLogsController < AdminController
  include SyncLogsConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index
  before_action :set_sync_reference, only: :resync

  #
  # This is the index action for Admin where he can view the sync_logs.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/sync_logs
  #
  def index
    @sync_logs = SyncLog.build_criteria(params).order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This is the resync action for sync_logs.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/sync_logs/:id/resync
  #
  def resync
    if @sync_log.resource.present?
      record = @sync_log.resource
      @erp_models = ErpModel.where(resource_class: record.class, action_name: @sync_log.action, is_active: true)
      @erp_models.each do |erp|
        @sync_log.sync(erp, record)
      end
      notice = "#{record.class} is queued to sync"
    else
      notice = 'Sync log resource absent'
    end
    redirect_back(fallback_location: root_path, notice: notice)
  end

  private

  def set_sync_reference
    @sync_log = SyncLog.where(id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, SyncLog]
  end

  #
  # def apply_policy_scope
  #   defined in SyncLogsConcern
  # end
end
