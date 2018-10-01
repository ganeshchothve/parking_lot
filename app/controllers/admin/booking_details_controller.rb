class Admin::BookingDetailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking_detail
  before_action :authorize_resource

  def set_booking_detail
    @booking_detail = BookingDetail.find(params[:id])
  end

  def authorize_resource
    authorize @booking_detail
  end
end
