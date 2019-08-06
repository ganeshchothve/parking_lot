module ReceiptsHelper
  def user_local_time(time)
    time.in_time_zone(current_user.time_zone)
  end

  def cancellation_link(receipt)
    if current_user.buyer?
      [:new, :buyer, :user_request, { request_type: UserRequest::Cancellation.model_name.element, requestable_id: receipt.id, requestable_type: 'Receipt'}]
    else
      [:new, :admin, receipt.user, :user_request, { request_type: UserRequest::Cancellation.model_name.element, requestable_id: receipt.id, requestable_type: 'Receipt'}]
    end
  end

  def filter_receipts_options(receipt_id)
    if receipt_id.present?
      Receipt.where(_id: receipt_id).map{|bd| [bd.name, bd.id]}
    else
      []
    end
  end
end

