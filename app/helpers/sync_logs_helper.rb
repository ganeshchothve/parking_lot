module SyncLogsHelper
  def custom_sync_logs_path
    admin_sync_logs_path
  end

  def redirect_link(sync_log)
    if sync_log.resource.present?
      if sync_log.resource_type == 'UserKyc'
        admin_user_kyc_path(sync_log.resource)
      elsif sync_log.resource_type == 'Receipt'
        admin_receipt_path(sync_log.resource)
      elsif sync_log.resource_type == 'User'
        admin_user_path(sync_log.resource)
      elsif sync_log.resource_type == 'ChannelPartner'
        channel_partner_path(sync_log.resource)
      elsif sync_log.resource_type == 'BookingDetail'
        admin_project_unit_path(sync_log.resource)
      end
    else
      resync_admin_sync_log_path(sync_log)
    end
  end
end
