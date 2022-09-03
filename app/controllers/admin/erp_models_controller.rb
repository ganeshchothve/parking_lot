class Admin::ErpModelsController < AdminController
  before_action :set_erp_model, except: :index
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  #
  # This is the index action for Admin where he can view the erp_models configured.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/erp_models
  #
  def index
    @erp_models = ErpModel.build_criteria(params).order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  # GET /admin/erp_models/new
  def new
    @erp_model = ErpModel.new
    render layout: false
  end

  def create
    respond_to do |format|
      if ErpModel.create(permitted_attributes([:admin, ErpModel.new]))
        format.html { redirect_to admin_erp_models_path, notice: 'Erp Model was successfully created.' }
        format.json { render json: @erp_model }
      else
        format.html { render :new, alert: @erp_model.errors.full_messages.uniq }
        format.json { render json: { errors: @erp_model.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  #
  # The edit action renders a form to edit the details of the erp_model.
  #
  # GET /admin/erp_models/:id/edit
  def edit
    render layout: false
  end

  #
  # The update action is called after edit to update the details.
  #
  # PATCH /admin/erp_models/:id
  #
  def update
    respond_to do |format|
      if @erp_model.update(permitted_attributes([:admin, @erp_model]))
        format.html { redirect_to admin_erp_models_path, notice: 'Erp Model was successfully updated.' }
        format.json { render json: @erp_model }
      else
        format.html { render :edit }
        format.json { render json: { errors: @erp_model.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private


  def set_erp_model
    @erp_model = ErpModel.where(id: params[:id]).first
  end

  def apply_policy_scope
    SyncLog.with_scope(policy_scope(ErpModel.criteria)) do
      yield
    end
  end

  def authorize_resource
    case params[:action]
    when 'index'
      authorize [:admin, ErpModel]
    when 'new', 'create'
      authorize [:admin, ErpModel.new]
    else
      authorize [:admin, @erp_model]
    end
  end
end
