class LocalDevise::RegistrationsController < Devise::RegistrationsController

  def destroy
    ApplicationLog.user_log(resource.id, 'deleted', RequestStore.store[:logging])
    super
  end

  private

  def after_inactive_sign_up_path_for(resource)
    ApplicationLog.user_log(resource.id, 'registered', RequestStore.store[:logging])
    root_path
  end

  def after_sign_up_path_for(resource)
    ApplicationLog.user_log(resource.id, 'registered', RequestStore.store[:logging])
    stored_location_for(resource) || signed_in_root_path(resource)
  end

  def after_update_path_for(resource)
    ApplicationLog.user_log(resource.id, 'edited', RequestStore.store[:logging])
    root_url
  end
end
