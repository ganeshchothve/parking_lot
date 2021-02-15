class Admin::ProjectsController < AdminController

  before_action :set_project, except: %i[index collaterals]
  before_action :authorize_resource, except: %i[collaterals]
  around_action :apply_policy_scope, only: %i[index collaterals]
  layout :set_layout

  #
  # This index action for Admin users where Admin can view all projects.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/projects
  #
  def index
    @projects = Project.all.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @projects.collect { |p| { id: p.id, name: p.ds_name } } }
        format.html {}
      else
        format.json { render json: @projects }
        format.html {}
      end
    end
  end

  #
  # This edit action for Admin users is called after edit.
  #
  # PATCH /admin/projects/:id
  #
  def edit
    render layout: false
  end

  #
  # This update action for Admin users is called after edit.
  #
  # PATCH /admin/projects/:id
  #
  def update
    parameters = permitted_attributes([:admin, @project])
    respond_to do |format|
      if @project.update(parameters)
        format.html { redirect_to request.referrer || admin_projects_path, notice: 'Project successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def collaterals
    @project = Project.where(id: params[:id]).first
    authorize_resource
    render layout: false
  end

  private

  def set_project
    @project = Project.where(id: params[:id]).first
    redirect_to dashboard_path, alert: 'Project not found' unless @project
  end

  def authorize_resource
    if %w[index collaterals].include?(params[:action])
      if params[:ds].to_s == 'true'
        authorize([:admin, Project], :ds?)
      else
        authorize [:admin, Project]
      end
    else
      authorize [:admin, @project]
    end
  end

  def apply_policy_scope
    custom_project_scope = Project.all.criteria
    Project.with_scope(policy_scope(custom_project_scope)) do
      yield
    end
  end

end
