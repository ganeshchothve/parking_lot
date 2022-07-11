# frozen_string_literal: true

class Mp::LocalDevise::UnlocksController < Devise::UnlocksController
  layout "mp/application"
  # GET /resource/unlock/new
  # def new
  #   super
  # end

  # POST /resource/unlock
  # def create
  #   super
  # end

  # GET /resource/unlock?unlock_token=abcdef
  # def show
  #   super
  # end

  # protected

  # The path used after sending unlock password instructions
  # def after_sending_unlock_instructions_path_for(resource)
  #   super(resource)
  # end

  # The path used after unlocking the resource
  # def after_unlock_path_for(resource)
  #   super(resource)
  # end

  private

  def after_unlock_path_for(resource)
    ApplicationLog.user_log(resource.id, 'unlocked', RequestStore.store[:logging])
    new_session_path(resource)
  end
end
