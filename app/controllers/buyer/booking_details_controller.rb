class Buyer::BookingDetailsController < BuyerController
  before_action :set_booking_detail
  before_action :authorize_resource

  def booking
    @project_unit = ProjectUnit.find(@booking_detail.project_unit_id)
    unattached_blocking_receipt = @booking_detail.user.unattached_blocking_receipt @project_unit.blocking_amount
    if unattached_blocking_receipt.present?
      @receipt = unattached_blocking_receipt
      @receipt.booking_detail_id = @booking_detail.id
      @booking_detail.under_negotiation!
      @receipt.project_unit_id = @project_unit.id
      @receipt.project_unit = @project_unit
    else
      @receipt = Receipt.new(creator: @booking_detail.user, user: @booking_detail.user, payment_mode: 'online', total_amount: current_client.blocking_amount, payment_gateway: current_client.payment_gateway, booking_detail_id: @booking_detail.id, project_unit_id: @project_unit.id)
      @receipt.account = selected_account(@booking_detail.project_unit)
      @receipt.total_amount = @project_unit.blocking_amount
      authorize([ current_user_role_group, Receipt.new(user: @booking_detail.user)], :new?)
    end
      # authorize [current_user_role_group, @project_unit]

    # authorize([current_user_role_group, @receipt], :create?)
    if @receipt.save
      if @receipt.status == "pending" # if we are just tagging an already successful receipt, we dont need to send the user to payment gateway
        if @receipt.payment_gateway_service.present?
          redirect_to @receipt.payment_gateway_service.gateway_url(@booking_detail.search.id)
        else
          @receipt.update_attributes(status: "failed")
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          redirect_to dashboard_path
        end
      else
        redirect_to buyer_user_path(@booking_detail.user)
      end
    else
      redirect_to checkout_user_search_path(project_unit_id: @project_unit.id)
    end
  end


  private


  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, @booking_detail]
  end
end
