# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  def index
  end

  def register
    if user_signed_in?
      redirect_to root_path
      flash[:notice] = "You have already been logged in"
    end
  end

  def check_and_register
    unless request.xhr?
      redirect_to root_path
    else
      if user_signed_in?
        respond_to do |format|
          format.json { render json: {error: "You have already been logged in", url: root_path}, status: :unprocessable_entity }
        end
      else
        @user = User.or([{email: params['email']}, {phone: params['phone']}, {lead_id: params['lead_id']}]).first #TODO: check if you want to find uniquess on lead id also
        if @user
          respond_to do |format|
            format.json { render json: {error: 'You have already registered. Email or Phone already taken. Please login', url: new_user_session_path}, status: :unprocessable_entity }
          end
        else
          generated_password = Devise.friendly_token.first(8)
          @user = User.new(email: params['email'], phone: params['phone'], name: params['name'], password: generated_password, lead_id: params[:lead_id])
          # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we are to use OTP based login

          respond_to do |format|
            if @user.save
              format.json { render json: {user: @user, success: 'User registration completed'}, status: :created }
            else
              format.json { render json: {errors: @user.errors.full_messages.uniq}, status: :unprocessable_entity }
            end
          end
        end
      end
    end
  end
end
