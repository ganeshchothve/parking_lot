# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  def index
  end

  def register
    if user_signed_in?
      redirect_to after_sign_in_path_for(current_user)
      flash[:notice] = "You have already been logged in"
    end
  end

  def check_and_register
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path : root_path)
    else
      if user_signed_in? && ['channel_partner', 'admin'].exclude?(current_user.role)
        respond_to do |format|
          format.json { render json: {errors: "You have already been logged in", url: root_path}, status: :unprocessable_entity }
        end
      else
        @user = User.or([{email: params['email']}, {phone: params['phone']}, {lead_id: params['lead_id']}]).first #TODO: check if you want to find uniquess on lead id also
        if @user
          respond_to do |format|
            format.json { render json: {errors: 'A user with these details has already registered', url: (user_signed_in? ? admin_users_path : new_user_session_path)}, status: :unprocessable_entity }
          end
        else
          @user = User.new(email: params['email'], phone: params['phone'], name: params['name'], lead_id: params[:lead_id])
          if user_signed_in?
            @user.channel_partner_id = current_user.id
          end
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
