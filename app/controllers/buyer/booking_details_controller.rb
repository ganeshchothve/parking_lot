class Buyer::BookingDetailsController < BuyerController
  include BookingDetailConcern
  around_action :apply_policy_scope, only: [:index]
  before_action :set_booking_detail, except: [:index]
  before_action :set_project_unit, except: [:index]
  before_action :set_receipt, except: [:index]
  before_action :authorize_resource, except: [:index]

  def index
    # authorize [:buyer, BookingDetail]
    @booking_details = BookingDetail.build_criteria params 
    @booking_details = @booking_details.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def show
    @scheme = @booking_detail.booking_detail_scheme
    render template: 'admin/booking_details/show' 
  end

  def show
    @scheme = @booking_detail.booking_detail_scheme
  end

  def booking
    if @receipt.save
      @booking_detail.under_negotiation!
      if @receipt.status == 'pending' # if we are just tagging an already successful receipt, we dont need to send the user to payment gateway
        if @receipt.payment_gateway_service.present?
          redirect_to @receipt.payment_gateway_service.gateway_url(@booking_detail.search.id)
        else
          @receipt.update_attributes(status: 'failed')
          flash[:notice] = "We couldn't redirect you to the payment gateway, please try again"
          redirect_to dashboard_path
        end
      else
        redirect_to buyer_user_path(@booking_detail.user)
      end
    else
      redirect_to checkout_user_search_path(@booking_detail.search)
    end
  end

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:id]).first
    redirect_to dashboard_path, alert: t('controller.booking_details.set_booking_detail_missing') if @booking_detail.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to dashboard_path, alert: t('controller.booking_details.set_project_unit_missing') if @project_unit.blank?
  end

  def set_receipt
    unattached_blocking_receipt = @booking_detail.user.unattached_blocking_receipt @project_unit.blocking_amount
    if unattached_blocking_receipt.present?
      @receipt = unattached_blocking_receipt
      @receipt.booking_detail_id = @booking_detail.id
    else
      @receipt = Receipt.new(creator: @booking_detail.user, user: @booking_detail.user, payment_mode: 'online', total_amount: current_client.blocking_amount, payment_gateway: current_client.payment_gateway, booking_detail_id: @booking_detail.id)
      @receipt.account ||= selected_account(current_client.payment_gateway.underscore, @booking_detail.project_unit)
      @receipt.total_amount = @project_unit.blocking_amount
      authorize([:buyer, @receipt], :create?)
    end
  end

  def authorize_resource
    authorize [:buyer, @booking_detail]
  end
end
