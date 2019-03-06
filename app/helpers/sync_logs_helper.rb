module SyncLogsHelper
  def custom_sync_logs_path
    admin_sync_logs_path
  end

  def redirect_link(sync_log)
    case sync_log.resource_type
    when 'UserKyc'
      admin_user_kyc_path(sync_log.resource)
    when 'Receipt'
      admin_receipt_path(sync_log.resource)
    when 'User'
      admin_user_path(sync_log.resource)
    when 'ChannelPartner'
      channel_partner_path(sync_log.resource)
    when 'BookingDetail'
      admin_project_unit_path(sync_log.resource)
    else
      resync_admin_sync_log_path(sync_log)
    end
  end
end