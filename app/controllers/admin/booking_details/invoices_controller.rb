class Admin::BookingDetails::InvoicesController < AdminController
  before_action :set_booking_detail

  def index
    authorize([:admin, Invoice])
    @invoices = Invoice.where(booking_detail_id: @booking_detail.id)#.where(Invoice.user_based_scope(current_user, params))
                       .asc(:ladder_stage)
                       .build_criteria(params)
                       .paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.html { render template: 'booking_details/invoices/index' }
    end
  end

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(id: params[:booking_detail_id]).first
  end
end
