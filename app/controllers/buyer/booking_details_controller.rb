class Buyer::BookingDetailsController < BuyerController
  include BookingDetailConcern
  around_action :apply_policy_scope, only: [:index]
  before_action :set_booking_detail, except: [:index]
  before_action :set_project_unit, except: [:index]
  before_action :set_receipt, except: [:index, :generate_booking_detail_form]
  before_action :authorize_resource, except: [:index]

  def index
    authorize [:buyer, BookingDetail]
    @booking_details = BookingDetail.where(booking_portal_client_id: current_client.try(:id)).build_criteria params
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
      @receipt.change_booking_detail_status
      redirect_to home_path(current_user), notice: t('controller.booking_details.booking_successful')
    else
      redirect_to search_path(@booking_detail.search), alert: @receipt.errors.full_messages
    end
  end

  def doc
    render layout: false
  end

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(booking_portal_client_id: current_client.try(:id), _id: params[:id]).first
    redirect_to home_path(current_user), alert: t('controller.booking_details.set_booking_detail_missing') if @booking_detail.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to home_path(current_user), alert: t('controller.booking_details.set_project_unit_missing') if @project_unit.blank?
  end

  def set_receipt
    unattached_blocking_receipt = @booking_detail.lead.unattached_blocking_receipt @project_unit.blocking_amount
    if unattached_blocking_receipt.present?
      @receipt = unattached_blocking_receipt
      @receipt.booking_detail_id = @booking_detail.id
    else
      @receipt = Receipt.new(creator: @booking_detail.user, user: @booking_detail.user, payment_mode: 'online', total_amount: current_client.blocking_amount, payment_gateway: current_client.payment_gateway, booking_detail_id: @booking_detail.id, booking_portal_client_id: current_client.try(:id))
      @receipt.account ||= selected_account(current_client.payment_gateway.underscore, @booking_detail.project_unit)
      @receipt.total_amount = @project_unit.blocking_amount
      authorize([:buyer, @receipt], :create?)
    end
  end

  def authorize_resource
    authorize [:buyer, @booking_detail]
  end
end
