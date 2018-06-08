# TODO: replace all messages & flash messages
class HomeController < ApplicationController



  def eoi
    render layout: false
  end

   def index
    first_name = params[:first_name]
    last_name = params[:last_name]
    email = params[:email]
    phone = params[:phone]
    lead_id = params[:lead_id]
    
          if user_signed_in? && ['channel_partner', 'admin', 'crm', 'sales', 'cp'].exclude?(current_user.role)

              flash[:notice] = "You have already been logged in"

          else
            @user = User.or([{email: params['email']}, {phone: params['phone']}, {lead_id: params['lead_id']}]).first #TODO: check if you want to find uniquess on lead id also
            if @user.present?
              message = 'A user with these details has already registered'
              if (!@user.confirmed? || (@user.channel_partner_id.blank? && @user.booking_details.blank?)) && @user.role?('user')
                if current_user.present? && current_user.role?('channel_partner')
                  @user.set(referenced_channel_partner_ids: [current_user.id], channel_partner_id: current_user.id)
                  ApplicationLog.log("channel_partner_changed", {from: @user.channel_partner_id, to: current_user.id}, RequestStore.store[:logging])
                end
                if @user.confirmed?
                  flash[:notice] = "A user with these details has already registered and has confirmed their account. We have linked his account to you channel partner login."
                else
                  flash[:notice]  = "A user with these details has already registered, but hasn't confirmed their account. We have resent the confirmation email to them, which has an account activation link."
                  @user.resend_confirmation_instructions
                end
              end
            else
              # splitted name into two firstname and lastname
              @user = User.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], mixpanel_id: params[:mixpanel_id])
              if user_signed_in?
                @user.channel_partner_id = current_user.id
              end
              # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we are to use OTP based login

                if @user.save
                  ApplicationLog.log("user_registered", {user_id: @user.id, role: @user.role}, RequestStore.store[:logging])
                  flash[:notice] = "User registration completed"
                else
                  flash[:notice] = @user.errors.full_messages.uniq
                end
              
            end          
        end
   render layout: "dashboard"
end


  def employee_register
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = "You have already been logged in"
    else
      render layout: "dashboard"
    end
  end

  def external_register
    response.headers["X-FRAME-OPTIONS"] = "ALLOWALL"
    render layout: false
  end

  def register
    if user_signed_in?
      redirect_to home_path(current_user)
      flash[:notice] = "You have already been logged in"
    else
      render layout: "dashboard"
    end
  end

  def check_and_register
    unless request.xhr?
      redirect_to (user_signed_in? ? after_sign_in_path : root_path)
    else
      if user_signed_in? && ['channel_partner', 'admin', 'crm', 'sales', 'cp'].exclude?(current_user.role)
        respond_to do |format|
          format.json { render json: {errors: "You have already been logged in", url: root_path}, status: :unprocessable_entity }
        end
      else
        @user = User.or([{email: params['email']}, {phone: params['phone']}, {lead_id: params['lead_id']}]).first #TODO: check if you want to find uniquess on lead id also
        if @user.present?
          message = 'A user with these details has already registered'
          if (!@user.confirmed? || (@user.channel_partner_id.blank? && @user.booking_details.blank?)) && @user.role?('user')
            if current_user.present? && current_user.role?('channel_partner')
              @user.set(referenced_channel_partner_ids: [current_user.id], channel_partner_id: current_user.id)
              ApplicationLog.log("channel_partner_changed", {from: @user.channel_partner_id, to: current_user.id}, RequestStore.store[:logging])
            end
            if @user.confirmed?
              message = "A user with these details has already registered and has confirmed their account. We have linked his account to you channel partner login."
            else
              message = "A user with these details has already registered, but hasn't confirmed their account. We have resent the confirmation email to them, which has an account activation link."
              @user.resend_confirmation_instructions
            end
          end
          respond_to do |format|
            format.json { render json: {errors: message}, status: :unprocessable_entity }
          end
        else
          # splitted name into two firstname and lastname
          @user = User.new(email: params['email'], phone: params['phone'], first_name: params['first_name'], last_name: params['last_name'], lead_id: params[:lead_id], mixpanel_id: params[:mixpanel_id])
          if user_signed_in?
            @user.channel_partner_id = current_user.id
          end
          # RegistrationMailer.welcome(user, generated_password).deliver #TODO: enable this. We might not need this if we are to use OTP based login
          respond_to do |format|
            if @user.save
              ApplicationLog.log("user_registered", {user_id: @user.id, role: @user.role}, RequestStore.store[:logging])
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
