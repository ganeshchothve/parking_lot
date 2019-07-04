class CustomPolicy < Struct.new(:user, :enable_users)
  include ApplicationHelper

  def inventory?
    ['superadmin', 'admin', 'sales_admin', 'sales', 'channel_partner'].include?(user.role) && user.role.in?(current_client.enable_actual_inventory)
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
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def erp_models?
    %w[superadmin].include?(user.role)
  end

  def user_kycs?
    "#{user.buyer? ? 'Buyer' : 'Admin'}::UserKycPolicy".constantize.new(user, UserKyc).index?
  end

  def portal_stage_priorities?
    "#{user.buyer? ? '' : 'Admin::'}PortalStagePriorityPolicy".constantize.new(user, PortalStagePriority).index?
  end
  def self.custom_methods
    %w[inventory emails smses audits referrals accounts phases sync_logs erp_models user_kycs portal_stage_priorities].sort
  end
end
