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

  def sync_logs?
    %w[superadmin admin sales_admin].include?(user.role)
  end

  def erp_models?
    %w[superadmin admin].include?(user.role)
  end

  def self.custom_methods
    %w[inventory emails smses audits sync_logs erp_models] 
  end
end
