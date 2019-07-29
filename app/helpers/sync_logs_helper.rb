module SyncLogsHelper
  def custom_sync_logs_path
    admin_sync_logs_path
  end

  def redirect_link(sync_log)
    case sync_log.resource_type
    when 'UserKyc'
      admin_user_kyc_path(sync_log.resource_id)
    when 'Receipt'
      admin_receipt_path(sync_log.resource_id)
    when 'User'
      admin_user_path(sync_log.resource_id)
    when 'ChannelPartner'
      channel_partner_path(sync_log.resource_id)
    when 'BookingDetail'
      admin_booking_detail_path(sync_log.resource_id)
    else
      resync_admin_sync_log_path(sync_log_id)
    end
  end
end
