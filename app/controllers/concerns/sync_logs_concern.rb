module SyncLogsConcern
  include Api
  extend ActiveSupport::Concern

  def resync
    record = @sync_reference.resource
    if @sync_reference.resource_type == 'User'
      details = UserDetailsSync.new('selldo', record, @sync_reference)
    elsif @sync_reference.resource_type == 'BookingDetail'
      details = BookingDetailsSync.new('selldo', record, @sync_reference)
    elsif @sync_reference.resource_type == 'Receipt'
      details = ReceiptDetailsSync.new('selldo', record, @sync_reference)
    elsif @sync_reference.resource_type == 'UserKyc'
      details = UserKycDetailsSync.new('selldo', record, @sync_reference)
    elsif @sync_reference.resource_type == 'ChannelPartner'
      details = ChannelPartnerDetailsSync.new('selldo', record, @sync_reference)
    end
    if record.erp_id.present?
      details.on_create
    else
      details.on_update
    end
  end

  private


  def set_sync_reference
    @sync_reference = SyncLog.where(id: params[:id]).first
  end

  def apply_policy_scope
    SyncLog.with_scope(policy_scope(SyncLog.criteria)) do
      yield
    end
   end
end
