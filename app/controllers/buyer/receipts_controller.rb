class Buyer::ReceiptsController < BuyerController
  include ReceiptsConcern
  before_action :set_receipt, except: [:index, :new, :create]

  layout :set_layout

  # GET /buyer/receipts
  def index
    authorize([:buyer, Receipt])

    @receipts = current_user.receipts.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @receipts.as_json(methods: [:name]) }
      format.html
    end
  end

  # GET /buyer/receipts/export
  # Defined in ReceiptsConcern

  # GET /buyer/receipts/:receipt_id/resend_success
  # Defined in ReceiptsConcern

  # GET /buyer/receipts/new
  def new
    @receipt = current_user.receipts.build({
      creator: current_user, payment_mode: 'online',
      total_amount: current_client.blocking_amount
    })
    authorize([:buyer, @receipt])
    render layout: false
  end

  # POST /buyer/receipts
  def create
    @receipt = current_user.receipts.build({
      payment_mode: 'online', creator: current_user,
      payment_gateway: current_client.payment_gateway,
      payment_type: 'agreement'
    })
    @receipt.assign_attributes(permitted_attributes([:buyer, @receipt]))
    @receipt.account = selected_account

    authorize([:buyer, @receipt])
    respond_to do |format|
      if @receipt.save
        url = dashboard_path
        if @receipt.payment_gateway_service.present?
          url = @receipt.payment_gateway_service.gateway_url(@receipt.user.get_search('').id)
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

  def set_receipt
    @receipt = current_user.receipts.where(_id: params[:id]).first
    redirect_to dashboard_path, alert: 'No receipts found' if @receipt.blank?
  end

end
