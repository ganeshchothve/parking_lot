class Admin::ErpModelsController < AdminController
  before_action :set_erp_model, except: :index
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @erp_models = ErpModel.build_criteria(params).order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def edit
    render layout: false
  end

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
    if params[:action] == 'index'
      authorize [:admin, ErpModel]
    else
      authorize [:admin, @erp_model]
    end
  end
end
