class Admin::Projects::UnitConfigurationsController < AdminController
  before_action :set_project
  before_action :set_unit_configuration, except: [:index]
  before_action :authorize_resource

  # GET /admin/projects/:project_id/unit_configurations
  #
  def index
    @unit_configurations = @project.unit_configurations.where(booking_portal_client_id: current_client.try(:id)).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @unit_configurations }
      format.html {}
    end
  end

  # GET /admin/projects/:project_id/unit_configurations/:id
  #
  def edit
    render layout: false
  end

  # PATCH /admin/projects/:project_id/unit_configurations/:id
  #
  def update
    parameters = permitted_attributes([:admin, @unit_configuration])
    @unit_configuration.booking_portal_client_id = current_client.try(:id)
    respond_to do |format|
      if @unit_configuration.update(parameters)
        format.html { redirect_to request.referrer || admin_project_unit_configurations_path, notice: I18n.t("controller.time_slots.notice.updated") }
      else
        errors = @unit_configuration.errors.full_messages
        errors.uniq!
        format.html { render :edit }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_project
    @project = Project.where(id: params[:project_id]).first
    redirect_to home_path(current_user), alert: I18n.t("controller.projects.alert.not_found") unless @project
  end

  def set_unit_configuration
    @unit_configuration = @project.unit_configurations.where(id: params[:id]).first
    redirect_to home_path(current_user), alert: I18n.t("controller.time_slots.alert.not_found") unless @unit_configuration
  end

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [:admin, UnitConfiguration.new(project_id: @project.id)]
    else
      authorize [:admin, @unit_configuration]
    end
  end
end
