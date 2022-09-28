class Admin::ApiLogsController < AdminController
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  def index
    @api_logs = ApiLog.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @api_logs }
      format.html {}
    end
  end

  private
  def authorize_resource
    authorize [current_user_role_group, ApiLog]
  end

  def apply_policy_scope
    custom_scope = ApiLog.where(ApiLog.user_based_scope(current_user, params))
    ApiLog.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
