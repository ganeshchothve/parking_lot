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
    # @erp_model = ErpModel.where().first
    # if record.erp_id present?
    # erp_model.action_name == "update"
    # else
    # erp_model.action_name == "create"
    # end
    @erp_model = ErpModel.new
    if @sync_log.resource_type == 'User'
      details = UserDetailsSync.new(@erp_model, record, @sync_log)
    elsif @sync_log.resource_type == 'BookingDetail'
      details = BookingDetailsSync.new(@erp_model, record, @sync_log)
    elsif @sync_log.resource_type == 'Receipt'
      details = ReceiptDetailsSync.new(@erp_model, record, @sync_log)
    elsif @sync_log.resource_type == 'UserKyc'
      details = UserKycDetailsSync.new(@erp_model, record, @sync_log)
    elsif @sync_log.resource_type == 'ChannelPartner'
      details = ChannelPartnerDetailsSync.new(@erp_model, record, @sync_log)
    end
  end

  private

  def set_sync_reference
    @sync_log = SyncLog.where(id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, SyncLog]
  end
end
