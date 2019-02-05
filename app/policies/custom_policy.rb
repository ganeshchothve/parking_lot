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


  def self.custom_methods
    ['inventory', 'emails', 'smses', 'audits', 'referrals']
  end
end
