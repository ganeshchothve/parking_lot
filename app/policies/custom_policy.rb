class CustomPolicy < Struct.new(:user, :enable_users)
  include ApplicationHelper

  def add_booking?
    current_client.enable_actual_inventory?(user)
  end

  def inventory?
    if user.role?(:channel_partner)
      user.role.in?(current_client.enable_actual_inventory) || (user.role.in?(current_client.enable_live_inventory) && user.enable_live_inventory)
    else
      ['superadmin', 'admin', 'sales_admin', 'sales', 'cp', 'cp_admin'].include?(user.role) && (user.role.in?(current_client.enable_actual_inventory) || user.role.in?(current_client.enable_live_inventory))
    end
  end

  def emails?
    EmailPolicy::Scope.new(user, Email).resolve
  end

  def smses?
    SmsPolicy::Scope.new(user, Sms).resolve
  end

  def audits?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::Audit::RecordPolicy".constantize.new(user, Audit::Record.new).index?
  end

  def referrals?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::ReferralPolicy".constantize.new(user, User).index?
  end

  def accounts?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::AccountPolicy".constantize.new(user, Account).index?
  end

  def phases?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::PhasePolicy".constantize.new(user, Phase).index?
  end

  def sync_logs?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::SyncLogPolicy".constantize.new(user, SyncLog).index?
  end

  def erp_models?
    %w[superadmin].include?(user.role)
  end

  def schemes?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::SchemePolicy".constantize.new(user, Scheme).index?
  end

  def incentive_schemes?
    current_client.enable_actual_inventory?(user) && %w[superadmin admin cp_admin].include?(user.role)
  end

  def user_kycs?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::UserKycPolicy".constantize.new(user, UserKyc).index?
  end

  def portal_stage_priorities?
    "#{user.buyer? ? '' : 'Admin::'}PortalStagePriorityPolicy".constantize.new(user, PortalStagePriority).index?
  end

  def user_requests?
    "#{user.buyer? ? '' : 'Admin::'}UserRequestPolicy".constantize.new(user, UserRequest).index?
  end

  def channel_partners?
    "#{user.buyer? ? '' : 'Admin::'}ChannelPartnerPolicy".constantize.new(user, ChannelPartner).index?
  end

  def checklists?
    "#{user.buyer? ? '' : 'Admin::'}ChecklistPolicy".constantize.new(user, Checklist).index?
  end

  def bulk_upload_reports?
    "#{user.buyer? ? '' : 'Admin::'}BulkUploadReportPolicy".constantize.new(user, BulkUploadReport).index?
  end

  def crms?
    "#{user.buyer? ? '' : 'Admin::'}Crm::BasePolicy".constantize.new(user, Crm::Base).index?
  end

  def api_logs?
    "#{user.buyer? ? '' : 'Admin::'}ApiLogPolicy".constantize.new(user, ApiLog).index?
  end

  def assets?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::AssetPolicy".constantize.new(user, Asset).index?
  end

  def self.custom_methods
    %w[schemes incentive_schemes user_requests channel_partners emails smses referrals accounts checklists bulk_upload_reports assets crms api_logs].sort
    # add_booking user_kycs portal_stage_priorities phases audits
  end
end
