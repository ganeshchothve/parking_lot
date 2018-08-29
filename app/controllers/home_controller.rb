# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  def index
  end

  def register
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = "You have already been logged in"
    else
      render layout: "application"
    end
  end

  def check_and_register
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path : root_path)
    else
      if user_signed_in? && current_user.buyer?
        message = "You have already been logged in"
        respond_to do |format|
          format.json { render json: {errors: "You have already been logged in", url: root_path}, status: :unprocessable_entity }
        end
      else
        query = []
        query << {email: params['email']} if params[:email].present?
        query << {phone: params['phone']} if params[:phone].present?
        query << {leaD_id: params['leaD_id']} if params[:leaD_id].present?
        @user = User.or(query).first #TODO: check if you want to find uniquess on lead id also
        if @user.present?
          message = 'A user with these details has already registered.'
          if !@user.confirmed? && @user.role?('user')
            if current_user.present? && current_user.role?('channel_partner')
              @user.set(referenced_manager_ids: ([current_user.id] + @user.referenced_manager_ids).uniq, manager_id: current_user.id)
            end
            if @user.confirmed?
              message = "A user with these details has already registered and has confirmed their account. We have linked his account to you channel partner login."
            else
              message = "A user with these details has already registered, but hasn't confirmed their account. We have resent the confirmation email to them, which has an account activation link."
              @user.send_confirmation_instructions if @user.email.present?
            end
          end
          respond_to do |format|
            format.json { render json: {errors: message, already_exists: true}, status: :unprocessable_entity }
          end
        else
          # splitted name into two firstname and lastname
          @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], mixpanel_id: params[:mixpanel_id])
          if user_signed_in?
            @user.manager_id = current_user.id
          elsif(cookies[:portal_cp_id].present?)
            @user.manager_id = cookies[:portal_cp_id]
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
