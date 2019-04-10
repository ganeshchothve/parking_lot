class Buyer::BookingDetails::ReceiptsController < BuyerController
  before_action :set_booking_detail
  before_action :set_project_unit

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "/admin/users/:user_id/project_units/:project_unit_id/receipts/new"
  def new
    @receipt = Receipt.new({
      creator: current_user, project_unit_id: @project_unit.id, user: current_user,
      total_amount: (@project_unit.status == "hold" ? @project_unit.blocking_amount : @booking_detail.pending_balance)
    })
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit receipt form.
  #
  # POST /admin/users/:user_id/project_units/:project_unit_id/receipts
  def create
    @receipt = Receipt.new(user: current_user, creator: current_user, project_unit_id: @project_unit.id, payment_gateway: current_client.payment_gateway, booking_detail_id: @booking_detail.id)
    @receipt.assign_attributes(permitted_attributes([:buyer, @receipt]))
    @receipt.account = selected_account(@receipt.project_unit)
    respond_to do |format|
      if @receipt.account.blank?
        flash[:alert] = "We do not have any Account Details for Transaction. Please ask Administrator to add."
        format.html { render 'new' }
      else
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
          format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
          format.html { render 'new' }
        end
      end
    end
  end

  private

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to root_path, alert: t('controller.booking_details.set_project_unit_missing'), status: 404 if @project_unit.blank?
  end

  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:booking_detail_id]).first
    redirect_to root_path, alert: t('controller.booking_details.set_booking_detail_missing'), status: 404 if @booking_detail.blank?
  end

end