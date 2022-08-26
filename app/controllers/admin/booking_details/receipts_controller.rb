class Admin::BookingDetails::ReceiptsController < AdminController
  before_action :set_booking_detail
  before_action :set_lead
  before_action :set_project_unit

  def index
    authorize([:admin, Receipt])
    @receipts = Receipt.where(booking_detail_id: @booking_detail.id).where(Receipt.user_based_scope(current_user, params))
                       .build_criteria(params)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'booking_details/receipts/index' }
    end
  end

  #
  # This new action always create a new receipt form for user's project unit receipt form.
  #
  # GET "/admin/users/:user_id/booking_details/:booking_detail_id/receipts/new"
  def new
    @amount_hash = {}
    PaymentType.in(name: Receipt::PAYMENT_TYPES).where(project_id: @project_unit.project_id).map { |x| @amount_hash[x.name.to_sym] = x.value(@project_unit).round }
    @receipt = Receipt.new(
      creator: current_user, user: @lead.user, lead: @lead, project: @lead.project, booking_detail: @booking_detail, total_amount: (@booking_detail.hold? ? @project_unit.blocking_amount : @booking_detail.pending_balance)
    )
    authorize([:admin, @receipt])
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit rerceipt form.
  #
  # POST /admin/users/:user_id/booking_details/:booking_detail_id/receipts
  def create
    @receipt = Receipt.new(user: @lead.user, lead: @lead, project: @lead.project, creator: current_user, booking_detail: @booking_detail)
    @receipt.assign_attributes(permitted_attributes([:admin, @receipt]))
    @receipt.payment_gateway ||= current_client.payment_gateway if @receipt.payment_mode == 'online'
    @receipt.account ||= selected_account(current_client.payment_gateway.underscore, @receipt)
    authorize([:admin, @receipt])
    respond_to do |format|
      if @receipt.save
        flash[:notice] = 'Receipt was successfully updated. Please upload documents'
        if @receipt.payment_mode == 'online'
          url = @receipt.payment_gateway_service.gateway_url(@booking_detail.search.id)
        else
          url = admin_booking_detail_receipts_path(@booking_detail, 'remote-state': assetables_path(assetable_type: @receipt.class.model_name.i18n_key.to_s, assetable_id: @receipt.id))
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

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "admin/booking_details/:booking_detail_id/receipts/lost_receipt"
  def lost_receipt
    @receipt = Receipt.new({
      creator: current_user, user_id: @lead.user, lead: @lead, project: @lead.project, payment_mode: 'online'
    })
    authorize([:admin, @receipt])
    render layout: false
  end

  private

  def set_lead
    @lead = Lead.where(_id: params[:lead_id]).first
    @lead = @booking_detail.lead unless @lead
    redirect_to dashboard_path, alert: 'Lead Not found', status: 404 if @lead.blank?
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
