class Admin::Projects::TokenTypesController < AdminController
  before_action :set_project
  before_action :set_token_type, except: [:index, :new, :create]
  before_action :authorize_resource

  #
  # This index action for Admin users where Admin can view all Token types for a Project.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/projects/:project_id/token_types
  #
  def index
    @token_types = @project.token_types.all.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @token_types }
      format.html {}
    end
  end

  #
  # This new action for Admin users is called after new.
  #
  # GET /admin/projects/:project_id/token_types
  #
  def new
    @token_type = @project.token_types.build(booking_portal_client: current_client)
    render layout: false
  end

  #
  # This edit action for Admin users is called after edit.
  #
  # GET /admin/projects/:project_id/token_types/:id
  #
  def edit
    render layout: false
  end

  # POST /admin/projects/:project_id/token_types/:id
  #
  def create
    @token_type = @project.token_types.build(booking_portal_client: current_client)
    @token_type.assign_attributes(permitted_attributes([current_user_role_group, @token_type]))

    respond_to do |format|
      if @token_type.save
        format.html { redirect_to admin_project_token_types_path(), notice: I18n.t("controller.token_types.notice.created") }
        format.json { render json: @token_type, status: :created }
      else
        errors = @token_type.errors.full_messages
        errors.uniq!
        format.html { render :new }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  #
  # This update action for Admin users is called after edit.
  #
  # PATCH /admin/projects/:project_id/token_types/:id
  #
  def update
    parameters = permitted_attributes([:admin, @token_type])
    respond_to do |format|
      if @token_type.update(parameters)
        format.html { redirect_to request.referrer || admin_project_token_types_path, notice: I18n.t("controller.token_types.notice.updated") }
      else
        errors = @token_type.errors.full_messages
        errors.uniq!
        format.html { render :edit }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  def token_init
    respond_to do |format|
      if @token_type.init
        format.html {redirect_to admin_project_token_types_path, notice: "#{@token_type.name}" + I18n.t("controller.token_types.notice.activated") }
      else
        format.html {redirect_to admin_project_token_types_path, alert: I18n.t("controller.token_types.alert.failed_to_activate", name: "#{@token_type.name}")}
      end
    end
  end

  def token_de_init
    respond_to do |format|
      if @token_type.de_init
        format.html {redirect_to admin_project_token_types_path, notice: "#{@token_type.name}" + I18n.t("controller.token_types.notice.deactivated") }
      else
        format.html {redirect_to admin_project_token_types_path, alert: I18n.t("controller.token_types.alert.failed_to_deactivate", name: "#{@token_type.name}")}
      end
    end
  end

  private

  def set_project
    @project = Project.where(booking_portal_client_id: current_client.try(:id), id: params[:project_id]).first
    redirect_to home_path(current_user), alert: I18n.t("controller.projects.alert.not_found") unless @project
  end

  def set_token_type
    @token_type = @project.token_types.where(id: params[:id]).first
    redirect_to home_path(current_user), alert: I18n.t("controller.token_types.alert.not_found") unless @token_type
  end

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [:admin, TokenType]
    elsif params[:action] == 'new'
      authorize [:admin, TokenType.new]
    elsif params[:action] == 'create'
      authorize [:admin, TokenType.new(permitted_attributes([:admin, TokenType.new]))]
    else
      authorize [:admin, @token_type]
    end
  end
end
