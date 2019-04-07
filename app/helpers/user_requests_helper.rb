module UserRequestsHelper
  def available_booking_for_request
    BookingDetail.where(user_id: @user_request.user_id, status: { '$in' => BookingDetail::BOOKING_STAGES }).collect{ |bd| [bd.name, bd.id]}
  end
end