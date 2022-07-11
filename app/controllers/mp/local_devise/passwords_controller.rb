# frozen_string_literal: true

class Mp::LocalDevise::PasswordsController < Devise::PasswordsController
  layout "mp/application"
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  def new
    self.resource = resource_class.new(login: params.dig(:user, :login))
  end

  private

  def after_resetting_password_path_for(resource)
    ApplicationLog.user_log(resource.id, 'password', RequestStore.store[:logging])
    stored_location_for(resource) || signed_in_root_path(resource)
  end
end
