class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def selldo
    omniauth = request.env['omniauth.auth']
    if @user = User.find_or_create_for_selldo_oauth(omniauth)
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
    else
      flash[:alert] = I18n.t("controller.alert.ask_support_to_register")
      redirect_to new_user_session_url
    end
  end

  def failure
    flash[:notice] = params[:message]
    redirect_to root_path
  end
end
