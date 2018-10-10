class CustomPolicy < Struct.new(:user, :enable_users)

  def inventory?
    ['superadmin', 'admin', 'sales_admin', 'sales'].include?(user.role)
  end


  def self.custom_methods
    ["inventory"]
  end
end
