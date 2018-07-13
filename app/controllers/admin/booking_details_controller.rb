class Admin::BookingDetailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking_detail
  before_action :authorize_resource
 
  # update action will be responsible for updating the TDS Doc upload from dashboard for booked flats
  def update
    respond_to do |format|
      if @booking_detail.update(permitted_attributes(@booking_detail))
        format.html { redirect_to home_path(current_user), notice: 'TDS Doc was uploaded successfully.' }
      else
        format.html { redirect_to home_path(current_user), notice: 'Please try to upload again.'}
      end
  	end
  end

  def set_booking_detail
    @booking_detail = BookingDetail.find(params[:id])
  end

  def authorize_resource
    authorize @booking_detail
  end
end
