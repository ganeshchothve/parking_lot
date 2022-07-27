class Admin::ProjectsController < AdminController
  before_action :set_project, except: %i[index collaterals new create third_party_inventory]
  before_action :authorize_resource, except: %i[collaterals third_party_inventory]
  around_action :apply_policy_scope, only: %i[index collaterals]
  before_action :fetch_kylas_products, only: %i[new edit]
  layout :set_layout

  #
  # This index action for Admin users where Admin can view all projects.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/projects
  #
  def index
    @projects = Project.all.build_criteria(params)
    @projects = @projects.filter_by_is_active(true) unless policy([current_user_role_group, Project.new(is_active: false)]).show?
    @projects = @projects.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json
      format.html {}
    end
  end

  def third_party_inventory
  end

  #
  # This new action for Admin users is called after new.
  #
  # PATCH /admin/projects/:id
  #
  def new
    @project = Project.new
    render layout: false
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
  def create
    @project = Project.new
    @project.assign_attributes(permitted_attributes([current_user_role_group, @project]))
    @project.creator = current_user
    @project.booking_portal_client_id = current_user.booking_portal_client_id

    respond_to do |format|
      if @project.save
        format.html { redirect_to admin_projects_path, notice: 'Project was successfully created.' }
        format.json { render json: @project, status: :created }
      else
        errors = @project.errors.full_messages
        errors << @project.specifications.collect{|x| x.errors.full_messages}  if @project.specifications.present?
        errors.uniq!
        format.html { render :new }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
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
        errors = @project.errors.full_messages
        errors << @project.specifications.collect{|x| x.errors.full_messages} if @project.specifications.present?
        errors.uniq!
        format.html { render :edit }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @incentive_scheme = @project.incentive_schemes.where(status: "approved", :starts_on.lte => Date.current, :ends_on.gte => Date.current, category: "brokerage", resource_class: "BookingDetail", brokerage_type: "sub_brokerage").first
  end

  def collaterals
    @project = Project.where(id: params[:id]).first
    @project ? authorize([:admin, @project]) : authorize([:admin, Project])
    render layout: false
  end

  def sync_on_selldo
    errors = @project.sync_on_selldo
    respond_to do |format|
      unless errors.present?
        format.html { redirect_to request.referrer || admin_projects_path, notice: 'Project synced on Sell.do successfully' }
      else
        if errors&.is_a?(Array)
          Note.create(notable: @project, note: "Sell.do Sync Errors</br>" + errors.to_sentence, creator: current_user)
          err_msg = 'Project was unable to sync due to some errors. Please check notes for details'
        elsif errors&.is_a?(String)
          err_msg = errors
        end
        format.html { redirect_to request.referrer || admin_projects_path, alert: err_msg}
      end
    end
  end

  private

  def set_project
    @project = Project.where(id: params[:id]).first
    if action_name == 'edit'
      render json: { errors: 'Project not found' }, status: :not_found unless @project
    else
      redirect_to dashboard_path, alert: 'Project not found' unless @project
    end
  end

  def authorize_resource
    if %w[index export].include?(params[:action])
      if params[:ds]
        policy([current_user_role_group, Project]).ds?
      else
        authorize [:admin, Project]
      end
    elsif params[:action] == 'new'
      authorize [:admin, Project.new]
    elsif params[:action] == 'create'
      authorize [:admin, Project.new(permitted_attributes([:admin, Project.new]))]
    else
      authorize [:admin, @project]
    end
  end

  def apply_policy_scope
    custom_project_scope = Project.where(Project.user_based_scope(current_user,params)).criteria
    Project.with_scope(policy_scope(custom_project_scope)) do
      yield
    end
  end

  def fetch_kylas_products
    @kylas_products = Kylas::FetchProducts.new(current_user).call
  end

end
