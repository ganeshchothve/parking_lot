class Admin::BookingDetailsController < AdminController
  include BookingDetailConcern
  around_action :apply_policy_scope, only: [:index, :mis_report]
  before_action :set_booking_detail, except: [:index, :mis_report]
  before_action :authorize_resource, except: [:index, :mis_report]
  before_action :set_project_unit, only: :booking
  before_action :set_receipt, only: :booking

  def index
    authorize [:admin, BookingDetail]
    @booking_details = BookingDetail.includes(:project_unit, :user, :booking_detail_schemes).build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def show
    @scheme = @booking_detail.booking_detail_scheme
  end

  def booking
    # This will return @receipt object
    # In before_action set booking_detail project_unit, receipt and redirect_to to dashboard_path when any one of this is missing.
    if @receipt.save
      @receipt.change_booking_detail_status
      redirect_to admin_user_path(@receipt.user), notice: t('controller.booking_details.booking_successful')
    else
      redirect_to checkout_user_search_path(@booking_detail.search), alert: @receipt.errors.full_messages
    end
  end

  def send_under_negotiation
    @booking_detail.under_negotiation!
    respond_to do |format|
      format.html { redirect_to admin_user_path(@booking_detail.user.id) }
    end
  end

  #
  # This mis_report action for Admin users where Admin will be mailed the report
  #
  # GET /admin/booking_details/mis_report
  #
  def mis_report
    BookingDetailMisReportWorker.perform_async(current_user.id.to_s)
    flash[:notice] = 'Your mis-report has been scheduled and will be emailed to you in some time'
    redirect_to request.referer || dashboard_path
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

  def authorize_resource
    authorize [:admin, @booking_detail]
  end

  def set_receipt
    @receipt = @booking_detail.user.unattached_blocking_receipt @project_unit.blocking_amount
    if @receipt.present?
      @receipt.booking_detail_id = @booking_detail.id
    else
      redirect_to new_admin_booking_detail_receipt_path(@booking_detail.user, @booking_detail), notice: t('controller.booking_details.set_receipt_missing')
    end
  end
end
