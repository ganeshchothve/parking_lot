class Admin::ClientPolicy < ClientPolicy

  def asset_create?
    ['admin', 'super_admin'].include?(user.role)
  end

end
