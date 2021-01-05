module UserRequestsHelper

  def custom_user_requests_path
    [current_user_role_group, UserRequest, request_type: :all]
  end

  def available_booking_for_request
    BookingDetail.where(user_id: @user_request.user_id, status: { '$in' => BookingDetail::BOOKING_STAGES }).collect{ |bd| [bd.name, bd.id]}
  end

  def get_new_user_request_url(klass, requestable)
    current_user.buyer? ? new_buyer_user_request_path(requestable_id: booking_detail.id, requestable_type: requestable.class.to_s, request_type: klass.model_name.element) : new_admin_user_user_request_path(user_id: booking_detail.user_id, requestable_id: booking_detail.id, requestable_type: requestable.class.to_s, request_type: klass.model_name.element)
  end

  def user_request_status_badge(user_request)
    case user_request.status
    when 'rejected'
      'danger'
    when 'pending'
      'primary'
    when 'resolved'
      'success'
    when 'processing'
      'warning'
    end
  end
end
