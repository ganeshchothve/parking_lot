module BookingDetailConcern
  extend ActiveSupport::Concern

  def generate_booking_detail_form
  end

  def apply_policy_scope
    custom_scope = BookingDetail.where(BookingDetail.user_based_scope(current_user, params))
    BookingDetail.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
