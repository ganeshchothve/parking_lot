class ProjectUnits::ReceiptsController < AdminController
  before_action :set_project_unit

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "/admin/users/:user_id/project_units/:project_unit_id/receipts/new"
  def new
    @receipt = Receipt.new({
      creator: current_user, project_unit_id: @project_unit.id, user: current_user,
      total_amount: (@project_unit.status == "hold" ? @project_unit.blocking_amount : @project_unit.pending_balance)
    })
    authorize([:buyer, @receipt])
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit rerceipt form.
  #
  # POST /admin/users/:user_id/project_units/:project_unit_id/receipts
  def create
    @receipt = Receipt.new(user: current_user, creator: current_user, project_unit_id: @project_unit.id)
    @receipt.assign_attributes(permitted_attributes(@receipt))

    authorize([:buyer, @receipt])

    respond_to do |format|
      if @receipt.save
        flash[:notice] = "Receipt was successfully updated. Please upload documents"
        url = "#{admin_user_receipts_path(current_user)}?remote-state=#{assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id)}"
        format.json{ render json: @receipt, location: url }
        format.html{ redirect_to url }
      else
        format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  private

  def set_user
    current_user = User.where(_id: params[:user_id]).first
    redirect_to admin_dashboard_path, alert: 'User Not found', status: 404 if current_user.blank?
  end

  def set_project_unit
    @project_unit = ProjectUnit.where(_id: params[:project_unit_id]).first
    redirect_to admin_dashboard_path, alert: 'Project Unit Not found', status: 404 if @project_unit.blank?
  end

end