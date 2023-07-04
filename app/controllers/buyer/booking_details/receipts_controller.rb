class Buyer::BookingDetails::ReceiptsController < BuyerController
  before_action :set_booking_detail
  before_action :set_user
  before_action :set_project_unit
  before_action :set_lead


  def index
    authorize([:buyer, Receipt])
    @receipts = @booking_detail.receipts.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'booking_details/receipts/index' }
    end
  end

  #
  # This new action always create a new receipt form for user's project unit rerceipt form.
  #
  # GET "/admin/users/:user_id/booking_details/:booking_detail_id/receipts/new"
  def new
    @amount_hash = {}
    PaymentType.where(booking_portal_client_id: current_client.try(:id)).in(name: Receipt::PAYMENT_TYPES).where(project_id: @project_unit.project_id).map { |x| @amount_hash[x.name.to_sym] = x.value(@project_unit).round }
    @receipt = Receipt.new(
                      creator: current_user,
                      user: @lead.user,
                      lead: @lead,
                      project: @lead.project,
                      booking_detail: @booking_detail,
                      total_amount: (@booking_detail.hold? ? @project_unit.blocking_amount : @booking_detail.pending_balance),
                      booking_portal_client_id: @lead.booking_portal_client_id
                      )
    authorize([current_user_role_group, @receipt])
    render layout: false
  end

  #
  # This create action always create a new receipt for user's project unit receipt form.
  #
  # POST /admin/users/:user_id/booking_details/:booking_detail_id/receipts
  def create
    @receipt = Receipt.new(
                        user: current_user,
                        creator: current_user,
                        payment_gateway: current_client.payment_gateway,
                        booking_detail_id: @booking_detail.id,
                        payment_type: 'agreement',
                        lead: @lead,
                        project: @booking_detail.project,
                        booking_portal_client_id: @lead.booking_portal_client_id
                        )
    @receipt.assign_attributes(permitted_attributes([:buyer, @receipt]))
    @receipt.account = selected_account(current_client.payment_gateway.underscore, @receipt)
    authorize([:buyer, @receipt])
    respond_to do |format|
      if @receipt.save
        if @receipt.payment_gateway_service.present?
          url = @receipt.payment_gateway_service.gateway_url(@booking_detail.search_id)
          format.html{ redirect_to url }
          format.json{ render json: {}, location: url }
        else
          flash[:notice] = I18n.t("controller.notice.failed_to_redirect_to_payment_gateway")
          @receipt.update_attributes(status: "failed")
          format.json{ render json: @receipt, location: home_path(current_user) }
          format.html{ redirect_to home_path(current_user) }
        end
      else
        format.json { render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  private

  def set_user
    @user = User.where(booking_portal_client_id: current_client.try(:id), _id: params[:user_id]).first
    @user = @booking_detail.user if !(@user.present?)
    redirect_to home_path(current_user), alert: I18n.t("controller.users.alert.not_found"), status: 404 if @user.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to root_path, alert: t('controller.booking_details.set_project_unit_missing'), status: 404 if @project_unit.blank?
  end

  def set_booking_detail
    @booking_detail = BookingDetail.where(booking_portal_client_id: current_client.try(:id), _id: params[:booking_detail_id], user_id: current_user.id).first
    redirect_to root_path, alert: t('controller.booking_details.set_booking_detail_missing'), status: 404 if @booking_detail.blank?
  end

  def set_lead
    @lead = @booking_detail.lead if @booking_detail.present?
    @lead = Lead.where(booking_portal_client_id: current_client.try(:id), user_id: current_user.id, project_id: params[:current_project_id]).first if @lead.blank?
    redirect_to root_path, alert: I18n.t("controller.leads.alert.not_found"), status: 404 if @lead.blank?
  end

end
