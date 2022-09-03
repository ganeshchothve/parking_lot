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
      erp_model = @sync_log.erp_model
      @sync_log.sync(erp_model, record)
      notice = "#{record.class} is queued to sync"
    else
      notice = 'Sync log resource absent'
    end
    redirect_back(fallback_location: root_path, notice: notice)
  end

  def create
    @sync_log = SyncLog.new(set_params)
    @sync_log.action = 'create'
    record = @sync_log.resource
    erp_model = @sync_log.erp_model
    respond_to do |format|
      if erp_model.is_active?
        @sync_log.sync(erp_model, record)
        flash[:notice] = 'Sync process has been started.'
      else
        flash[:alert] = 'Sync details are missing.'
      end
      format.html { redirect_to request.referer || root_path }
    end
  end


  private

  def set_sync_reference
    @sync_log = SyncLog.where(id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, SyncLog]
  end

  def set_params
    params.require(:sync).permit(:erp_model_id, :erp_model_id, :resource_type, :resource_id)
  end

  #
  # def apply_policy_scope
  #   defined in SyncLogsConcern
  # end
end
