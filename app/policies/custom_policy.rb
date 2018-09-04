class CustomPolicy < Struct.new(:user, :enable_users)

  def self.custom_methods
    []
  end
end
