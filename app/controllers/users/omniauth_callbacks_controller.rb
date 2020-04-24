class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def selldo
    omniauth = request.env['omniauth.auth']
    @user = User.find_or_create_for_selldo_oauth(omniauth)
    @user.update_selldo_credentials(omniauth)
    if @user.save
      session[:user_id] = omniauth
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
    else
      flash[:alert] = "Please ask Sell.Do support to register your account."
      redirect_to new_user_session_url
    end
  end

  def failure
    flash[:notice] = params[:message]
    redirect_to root_path
  end
end
