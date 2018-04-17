# TODO: replace all messages & flash messages
class HomeController < ApplicationController
  def index
    render layout: false
  end

  def eoi
    render layout: false
  end

  def register
    if user_signed_in?
      redirect_to after_sign_in_path_for(current_user)
      flash[:notice] = "You have already been logged in"
    else
      render layout: "dashboard"
    end
  end

  def check_and_register
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path : root_path)
    else
      if user_signed_in? && ['channel_partner', 'admin', 'crm', 'sales'].exclude?(current_user.role)
        respond_to do |format|
          format.json { render json: {errors: "You have already been logged in", url: root_path}, status: :unprocessable_entity }
        end
      else
        @user = User.or([{email: params['email']}, {phone: params['phone']}, {lead_id: params['lead_id']}]).first #TODO: check if you want to find uniquess on lead id also
        if @user.present?
          message = 'A user with these details has already registered'
          if !@user.confirmed? || (@user.channel_partner_id.blank? && @user.booking_details.blank?)
            @user.set(channel_partner_id: current_user.id) if current_user.present? && current_user.role?('channel_partner')
            if @user.confirmed?
              message = "A user with these details has already registered and has confirmed their account. We have linked his account to you channel partner login."
            else
              message = "A user with these details has already registered, but hasn't confirmed their account. We have resent the confirmation email to them, which has an account activation link."
            end
            @user.resend_confirmation_instructions
          end
          respond_to do |format|
            format.json { render json: {errors: message, url: (user_signed_in? ? admin_users_path : new_user_session_path)}, status: :unprocessable_entity }
          end
        else
          # splitted name into two firstname and lastname
          @user = User.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id])
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
