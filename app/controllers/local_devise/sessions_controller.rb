class LocalDevise::SessionsController < Devise::SessionsController
  def create
    if params[self.resource_name][:login_otp].present?
      user = self.resource_class.find_for_database_authentication(params[resource_name])
      if user.authenticate_otp(params[self.resource_name][:login_otp], drift: 60)
        self.resource = user
      else
        throw(:warden, auth_options)
      end
    else
      self.resource = warden.authenticate!(auth_options)
    end
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def otp
    self.resource = self.resource_class.find_for_database_authentication(params[resource_name])
    respond_to do |format|
      if self.resource
        # TODO: handle max attempts to be 3 in 60 min
        SMSWorker.perform_async(self.resource.phone, "Your OTP for login is #{resource.otp_code}. ")
        if Rails.env.development?
          Rails.logger.info "---------------- #{resource.otp_code} ----------------"
        end
        format.json { render json: {errors: ""}, status: 200 }
      else
        format.json { render json: {errors: "Please enter a valid login"}, status: :unprocessable_entity }
      end
    end
  end
end
