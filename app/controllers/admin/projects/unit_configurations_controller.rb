class Admin::Projects::UnitConfigurationsController < AdminController
  before_action :set_project
  before_action :set_unit_configuration, except: [:index]
  before_action :authorize_resource

  # GET /admin/projects/:project_id/unit_configurations
  #
  def index
    @unit_configurations = @project.unit_configurations.all.paginate(page: params[:page] || 1, per_page: params[:per_page])
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
    redirect_to dashboard_path, alert: I18n.t('controller.booking_details.set_project_missing') unless @project
  end

  def set_unit_configuration
    @unit_configuration = @project.unit_configurations.where(id: params[:id]).first
    redirect_to dashboard_path, alert: I18n.t("controller.time_slots.alert.time_slot_missing") unless @unit_configuration
  end

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [:admin, UnitConfiguration]
    else
      authorize [:admin, @unit_configuration]
    end
  end
end
