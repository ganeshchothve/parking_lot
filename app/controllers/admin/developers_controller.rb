class Admin::DevelopersController < AdminController
  before_action :set_developer, except: %i[index new]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]
  layout :set_layout

  #
  # This index action for Admin users where Admin can view all developers.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/developers
  #
  def index
    @developers = Developer.all.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @developers.collect { |p| { id: p.id, name: p.ds_name } } }
        format.html {}
      else
        format.json { render json: @developers }
        format.html {}
      end
    end
  end

  #
  # This new action for Admin users is called after new.
  #
  # PATCH /admin/developers/:id
  #
  def new
    @developer = Developer.new
    render layout: false
  end

  #
  # This edit action for Admin users is called after edit.
  #
  # PATCH /admin/developers/:id
  #
  def edit
    render layout: false
  end

  #
  # This update action for Admin users is called after edit.
  #
  # PATCH /admin/developers/:id
  #
  def update
    parameters = permitted_attributes([:admin, @developer])
    respond_to do |format|
      if @developer.update(parameters)
        format.html { redirect_to request.referrer || admin_developers_path, notice: 'Developer successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @developer.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_developer
    @developer = Developer.where(id: params[:id]).first
    redirect_to dashboard_path, alert: 'Developer not found' unless @developer
  end

  def authorize_resource
    if %w[index export].include?(params[:action])
      authorize [:admin, Developer]
    elsif params[:action] == 'new'
      authorize [:admin, Developer.new]
    else
      authorize [:admin, @developer]
    end
  end

  def apply_policy_scope
    custom_developer_scope = Developer.all.criteria
    Developer.with_scope(policy_scope(custom_developer_scope)) do
      yield
    end
  end

end
