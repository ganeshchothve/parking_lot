class LocalDevise::PasswordsController < Devise::PasswordsController

  def new
    self.resource = resource_class.new(login: params.dig(:user, :login))
  end

  private

  def after_resetting_password_path_for(resource)
    ApplicationLog.user_log(resource.id, 'password', RequestStore.store[:logging])
    stored_location_for(resource) || signed_in_root_path(resource)
  end

end
