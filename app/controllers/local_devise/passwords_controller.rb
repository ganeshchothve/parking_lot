class LocalDevise::PasswordsController < Devise::PasswordsController

  def new
    self.resource = resource_class.new(login: params.dig(:user, :login))
  end

  private

  def after_resetting_password_path_for(resource)
    ApplicationLog.user_log(resource.id, 'password', RequestStore.store[:logging])
    stored_location_for(resource) || signed_in_root_path(resource)
  end

  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   unless is_marketplace?
  #     new_session_path(resource_name)
  #   else
  #     new_user_session_path(namespace: 'mp')
  #   end
  # end

end
