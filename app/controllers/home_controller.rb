# TODO: replace all messages & flash messages
class HomeController < ApplicationController

  skip_before_action :set_current_client, only: :welcome

  def index
  end

  def welcome
    render layout: 'welcome'
  end

  def register
    @resource = User.new
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = "You have already been logged in"
    else
      render layout: "devise"
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
          # Checks for when channel_partner adds a new user.
          if @user.role?('user')
            if !@user.confirmed?
              if current_user.present? && current_user.role?('channel_partner') && @user.manager_id.present? && current_client.enable_lead_conflicts?
                @user.set(referenced_manager_ids: ([current_user.id] + @user.referenced_manager_ids).uniq, manager_id: current_user.id)
                NotifyAdminWorker.perform_async( @user.id, current_user.id )
                message = "A user with these details has already registered, but hasn't confirmed their account. We have linked his account to your channel partner login. We have resent the confirmation email to them, which has an account activation link."
                @user.send_confirmation_instructions if @user.email.present?
              end
            else
              message = "A user with these details has already registered and has confirmed their account."
            end
          end
          respond_to do |format|
            format.json { render json: {errors: message, already_exists: true}, status: :unprocessable_entity }
          end
        else
          # splitted name into two firstname and lastname
          @user = User.new(booking_portal_client_id: current_client.id, email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], mixpanel_id: params[:mixpanel_id])

          if current_client.enable_referral_bonus &&  !params[:referral_code].blank?
            @user.referred_by = User.where(referral_code: params[:referral_code])[0]
          end

          if user_signed_in?
            @user.manager_id = current_user.id
          else
            @user.manager_id = cookies[:portal_cp_id] if(cookies[:portal_cp_id].present?)
            @user.set_utm_params(cookies)
          end
          # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we use otp based login
          # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we are to use otp based login

          respond_to do |format|
            if @user.save
              SelldoLeadUpdater.perform_async(@user.id, 'registered')
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

