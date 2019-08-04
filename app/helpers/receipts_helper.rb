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

  def available_statuses receipt
    if receipt.new_record?
      [ 'pending' ]
    else
      statuses = receipt.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end

  def i_gree_label
    if current_user.id == @receipt.user_id
      t('global.i_agree')
    else
      t('global.i_gree_be_half_of', name: @receipt.user.name)
    end
  end
end

