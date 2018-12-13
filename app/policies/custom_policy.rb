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


  def self.custom_methods
    ["inventory", 'emails', 'smses' ]
  end
end
