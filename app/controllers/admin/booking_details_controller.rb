class Admin::BookingDetailsController < AdminController
  before_action :get_booking_details, only: [:index]
  before_action :set_booking_detail, except: [:index]
  before_action :authorize_resource, except: [:index]

  def index
    @booking_details = @booking_details.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def show
    @scheme = @booking_detail.booking_detail_scheme
  end

  def booking
    @project_unit = ProjectUnit.find(@booking_detail.project_unit_id)
    unattached_blocking_receipt = @booking_detail.user.unattached_blocking_receipt @project_unit.blocking_amount
    if unattached_blocking_receipt.present?
      @receipt = unattached_blocking_receipt
      @receipt.booking_detail_id = @booking_detail.id
      @booking_detail.under_negotiation!
    else
      @receipt = Receipt.new(creator: @search.user, user: @search.user, payment_mode: 'online', total_amount: current_client.blocking_amount, payment_gateway: current_client.payment_gateway, booking_detail_id: @booking_detail.id)
      @receipt.account = selected_account(@search.project_unit)
      @receipt.total_amount = @project_unit.blocking_amount
      authorize([ current_user_role_group, Receipt.new(user: @booking_detail.user)], :new?)
    end
      # authorize [current_user_role_group, @project_unit]
      @receipt.project_unit_id = @project_unit.id
      @receipt.project_unit = @project_unit

    # authorize([current_user_role_group, @receipt], :create?)
    if @receipt.save
      if @receipt.status == "pending" # if we are just tagging an already successful receipt, we dont need to send the user to payment gateway
        if @receipt.payment_gateway_service.present?
          redirect_to @receipt.payment_gateway_service.gateway_url(@search.id)
        else
          @receipt.update_attributes(status: "failed")
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          redirect_to dashboard_path
        end
      else
        redirect_to admin_user_path(@receipt.user)
      end
    else
      redirect_to checkout_user_search_path(project_unit_id: @project_unit.id)
    end
  end

  def send_under_negotiation
    @booking_detail.under_negotiation!
    respond_to do |format|
      format.html { redirect_to admin_user_path(@booking_detail.user.id) }
    end
  end

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, @booking_detail]
  end

  def get_booking_details
    if params[:user_id].present?
      @booking_details = BookingDetail.where(user_id: params[:user_id])
    else
      @booking_details = BookingDetail.all
    end
  end
end
