class Admin::ApiLogsController < AdminController
  before_action :authorize_resource

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
end
