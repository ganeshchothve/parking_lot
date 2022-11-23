class Buyer::ReceiptsController < BuyerController
  include ReceiptsConcern

  before_action :set_lead, except: [:index, :show, :resend_success]
  before_action :set_receipt, except: [:index, :new, :create]
  around_action :apply_policy_scope, only: :index

  layout :set_layout

  # GET /buyer/receipts/export
  # Defined in ReceiptsConcern

  # GET /buyer/receipts/:receipt_id/resend_success
  # Defined in ReceiptsConcern

  # GET /buyer/leads/lead_id/receipts/new
  def new
    @amount_hash = {}
    @lead.project.token_types.all.select{|tt| tt.incrementor_exists?}.map { |x| @amount_hash[x.id.to_s] = x.token_amount }

    if params.dig(:booking_detail_id).present?
      @booking_detail = BookingDetail.where(booking_portal_client_id: current_client.try(:id), id: params[:booking_detail_id]).first
      @amount_hash['agreement'] = @booking_detail.pending_balance
      payment_type = "agreement"
    else
      payment_type = "token"
    end

    @receipt = @lead.receipts.build({
      user: @lead.user, project_id: @lead.project_id,
      creator: current_user, payment_mode: 'online',
      payment_type: payment_type,
      booking_detail_id: params.dig(:booking_detail_id),
      total_amount: @booking_detail.present? ? @booking_detail.pending_balance : @lead.project.blocking_amount,
      booking_portal_client_id: @lead.booking_portal_client_id,
    })
    authorize([:buyer, @receipt])
    render layout: false
  end

  # POST /buyer/leads/lead_id/receipts
  def create
    @receipt = @lead.receipts.build({
      user: @lead.user, project_id: @lead.project_id,
      payment_mode: 'online', creator: current_user,
      payment_gateway: current_client.payment_gateway,
      payment_type: 'token'
    })
    @receipt.assign_attributes(permitted_attributes([:buyer, @receipt]))
    @receipt.booking_portal_client_id = @lead.booking_portal_client_id
    @receipt.account = selected_account(current_client.payment_gateway.underscore, @receipt)

    authorize([:buyer, @receipt])
    respond_to do |format|
      if @receipt.save
        url = home_path(current_user)
        if @receipt.payment_gateway_service.present?
          url = @receipt.payment_gateway_service.gateway_url(@receipt.lead.get_search('').id)
          format.html{ redirect_to url }
          format.json{ render json: {}, location: url }
        else
          flash[:notice] = I18n.t("controller.notice.failed_to_redirect_to_payment_gateway")
          @receipt.update_attributes(status: "failed")
          url = home_path(current_user)
          format.json{ render json: @receipt, location: url }
          format.html{ redirect_to url }
        end
      else
        flash[:alert] = @receipt.errors.full_messages
        format.json { render json: {errors: flash[:alert] }, status: :unprocessable_entity }
        format.html { render 'new' }
      end
    end
  end

  def show
    authorize([:buyer, @receipt])
    render template: 'receipts/show'
  end

  private

  def set_lead
    @lead = Lead.where(booking_portal_client_id: current_client.try(:id), user_id: current_user.id, project_id: params[:current_project_id]).first
    redirect_to home_path(current_user), alert: I18n.t("controller.leads.alert.not_found"), status: 404 if @lead.blank?
  end

  def set_receipt
    lead = Lead.where(booking_portal_client_id: current_client.try(:id), user_id: current_user.id, project_id: params[:current_project_id]).first
    @receipt = lead.receipts.where(booking_portal_client_id: current_client.try(:id), _id: params[:id]).first
    redirect_to home_path(current_user), alert: I18n.t("controller.receipts.alert.not_found"), status: 404 if @receipt.blank?
  end

end
