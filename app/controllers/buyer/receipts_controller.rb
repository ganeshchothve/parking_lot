class Buyer::ReceiptsController < BuyerController
  before_action :set_receipt, except: [:index, :export, :new, :create, :direct]
  # before_action :set_project_unit
  # before_action :authorize_resource
  # around_action :apply_policy_scope, only: [:index, :export]

  layout :set_layout

  def index
    @receipts = current_user.receipts.order_by([:created_at, :desc]).paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
  end

  def show
    @receipt = Receipt.find(params[:id])
    authorize @receipt
  end

  def new
    @receipt = current_user.receipts.build({
      creator: current_user, payment_mode: 'online',
      total_amount: current_client.blocking_amount
    })

    authorize([:buyer, @receipt])
    render layout: false
  end

  def create
    @receipt = current_user.receipts.build({
      payment_mode: 'online', creator: current_user,
      payment_gateway: current_client.payment_gateway
    })

    @receipt.assign_attributes(permitted_attributes(@receipt))

    authorize([:buyer, @receipt])

    respond_to do |format|
      if @receipt.save
        url = dashboard_path
        if @receipt.payment_gateway_service.present?
          url = @receipt.payment_gateway_service.gateway_url(@receipt.user.get_search(@receipt.project_unit_id).id)
          format.html{ redirect_to url }
          format.json{ render json: {}, location: url }
        else
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          @receipt.update_attributes(status: "failed")
          url = dashboard_path
          format.json{ render json: @receipt, location: url }
          format.html{ redirect_to url }
        end
      else
        format.json { render json: {errors: @receipt.errors.full_messages}, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @receipt.update(permitted_attributes(@receipt))
        format.html { redirect_to admin_user_receipts_path(@user), notice: 'Receipt was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: {errors: @receipt.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_receipt
    @receipt = Receipt.find(params[:id])
  end

  def set_project_unit
    @project_unit = if params[:project_unit_id].present?
      ProjectUnit.find(params[:project_unit_id])
    elsif params[:receipt].present? && params[:receipt][:project_unit_id].present?
      ProjectUnit.find(params[:receipt][:project_unit_id])
    elsif @receipt.present?
      @receipt.project_unit
    end
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize Receipt
    elsif params[:action] == "new" || params[:action] == "create" || params[:action] == "direct"
      authorize Receipt.new(user_id: @user.id, project_unit_id: (@project_unit.present? ? @project_unit.id : nil))
    else
      authorize @receipt
    end
  end
end
