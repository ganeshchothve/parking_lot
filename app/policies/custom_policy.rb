class CustomPolicy < Struct.new(:user, :enable_users)

  def inventory?
    ['superadmin', 'admin', 'sales_admin', 'sales'].include?(user.role)
  end

  def emails?
    true
  end

  def smses?
    true
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
    return true
    %w[admin ].include?(user.role)
  end

  def self.custom_methods
    %w[inventory emails smses audits referrals accounts phases sync_logs erp_models user_kycs].sort
  end
end
