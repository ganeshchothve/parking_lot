class Admin::Audit::EntryPolicy < Audit::EntryPolicy
  def show?
    %w[superadmin admin].include?(user.role)
  end
end
