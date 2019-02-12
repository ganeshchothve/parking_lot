class Admin::BookingDetailsController < AdminController
  before_action :set_booking_detail
  before_action :authorize_resource

  private


  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:id]).first
  end

  def authorize_resource
    authorize [:admin, @booking_detail]
  end
end
