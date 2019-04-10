class Admin::ClientPolicy < ClientPolicy

  def asset_create?
    ['admin', 'superadmin'].include?(user.role)
  end

end
