class Admin::BookingDetails::ReceiptsController < AdminController
  before_action :set_user
  before_action :set_booking_detail
  before_action :set_project_unit

  def index
    authorize([:admin, Receipt])
    @receipts = Receipt.where(booking_detail_id: @booking_detail.id).where(Receipt.user_based_scope(current_user, params))
                       .build_criteria(params)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This new action always create a new receipt form for user's project unit receipt form.
  #
  # GET "/admin/users/:user_id/booking_details/:booking_detail_id/receipts/new"
  def new
    @receipt = Receipt.new(
      creator: current_user, user: @user, booking_detail: @booking_detail, total_amount: (@booking_detail.hold? ? @project_unit.blocking_amount : @booking_detail.pending_balance)
    )
    authorize([:admin, @receipt])
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit rerceipt form.
  #
  # POST /admin/users/:user_id/booking_details/:booking_detail_id/receipts
  def create
    @receipt = Receipt.new(user: @user, creator: current_user, booking_detail: @booking_detail)
    @receipt.assign_attributes(permitted_attributes([:admin, @receipt]))
    @receipt.payment_gateway ||= current_client.payment_gateway if @receipt.payment_mode == 'online'
    @receipt.account ||= selected_account(@booking_detail.project_unit)
    authorize([:admin, @receipt])
    respond_to do |format|
      if @receipt.save
        flash[:notice] = 'Receipt was successfully updated. Please upload documents'
        if @receipt.payment_mode == 'online'
          url = @receipt.payment_gateway_service.gateway_url(@booking_detail.search.id)
        else
          url = admin_user_receipts_path(@user, 'remote-state': assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id))
        end
        format.json { render json: @receipt, location: url }
        format.html { redirect_to url }
      else
        flash[:alert] = @receipt.errors.full_messages
        format.json { render json: { errors: flash[:alert] }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  private

  def set_user
    @user = User.where(_id: params[:user_id]).first
    redirect_to dashboard_path, alert: 'User Not found', status: 404 if @user.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to root_path, alert: t('controller.booking_details.set_project_unit_missing'), status: 404 if @project_unit.blank?
  end

  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:booking_detail_id]).first
    redirect_to root_path, alert: t('controller.booking_details.set_booking_detail_missing'), status: 404 if @booking_detail.blank?
  end
end
