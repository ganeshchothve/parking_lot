class Buyer::BookingDetails::ReceiptsController < BuyerController
  before_action :set_booking_detail
  before_action :set_user
  before_action :set_project_unit


  def index
    authorize([:buyer, Receipt])
    @receipts = @booking_detail.receipts.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "/admin/users/:user_id/booking_details/:booking_detail_id/receipts/new"
  def new
    @receipt = Receipt.new({
      creator: current_user, user: current_user, booking_detail: @booking_detail,
      total_amount: ( @booking_detail.hold? ? @booking_detail.project_unit_blocking_amount : @booking_detail.pending_balance)
    })
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit receipt form.
  #
  # POST /admin/users/:user_id/booking_details/:booking_detail_id/receipts
  def create
    @receipt = Receipt.new(user: current_user, creator: current_user,payment_gateway: current_client.payment_gateway, booking_detail_id: @booking_detail.id, payment_type: 'agreement')
    @receipt.assign_attributes(permitted_attributes([:buyer, @receipt]))
    @receipt.account = selected_account(@booking_detail.project_unit)
    # authorize([:buyer, @receipt])
    #TODO: found this removed in conflict, find reason and add authorization
    @receipt.account = selected_account(current_client.payment_gateway.underscore, @booking_detail.project_unit)
    respond_to do |format|
      if @receipt.save
        if @receipt.payment_gateway_service.present?
          url = @receipt.payment_gateway_service.gateway_url(@booking_detail.search_id)
          format.html{ redirect_to url }
          format.json{ render json: {}, location: url }
        else
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          @receipt.update_attributes(status: "failed")
          format.json{ render json: @receipt, location: dashboard_path }
          format.html{ redirect_to dashboard_path }
        end
      else
        format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  private

  def set_user
    @user = User.where(_id: params[:user_id]).first
    @user = @booking_detail.user if !(@user.present?)
    redirect_to dashboard_path, alert: 'User Not found', status: 404 if @user.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to root_path, alert: t('controller.booking_details.set_project_unit_missing'), status: 404 if @project_unit.blank?
  end

  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:booking_detail_id], user_id: current_user.id).first
    redirect_to root_path, alert: t('controller.booking_details.set_booking_detail_missing'), status: 404 if @booking_detail.blank?
  end
end
