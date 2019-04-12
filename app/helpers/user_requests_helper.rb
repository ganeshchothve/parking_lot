module UserRequestsHelper
  def available_booking_for_request
    BookingDetail.where(user_id: @user_request.user_id, status: { '$in' => BookingDetail::BOOKING_STAGES }).collect{ |bd| [bd.name, bd.id]}
  end

  def get_new_user_request_url(klass, booking_detail)
    current_user.buyer? ? new_buyer_user_request_path(booking_detail_id: booking_detail.id, request_type: klass.model_name.element) : new_admin_user_user_request_path(user_id: booking_detail.user_id, booking_detail_id: booking_detail.id, request_type: klass.model_name.element)
  end
end