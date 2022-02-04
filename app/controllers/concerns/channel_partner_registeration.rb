module ChannelPartnerRegisteration
  extend ActiveSupport::Concern

  def find_or_create_cp_user
    respond_to do |format|
      if request.format.json?
        handle_json_request
      else
        create_cp_user
        if @user.save
          format.html { redirect_to new_user_session_path, notice: 'Successfully registered' }
        else
          format.html { render :new, alert: @user.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end
  end

  # {
  #   "channel_partner": {
  #     "company_name": "FreshCP",
  #     "first_name": "fresh",
  #     "last_name": "cp",
  #     "phone": "+919896312345",
  #     "email": "fresh.cp@sell.do",
  #     "interested_services": [
  #       "Work on Mandates",
  #       "Lead Generation Help"
  #     ],
  #     "regions": [
  #       "Pune South",
  #       "Pune West",
  #       "Pune East",
  #       "Others"
  #     ],
  #     "referral_code": "",
  #     "rera_applicable": "false",
  #     "rera_id": ""
  #     "primary_user_id": "61dbfe17fa115b5b834760e4"
  #   }
  # }
  # TODO: for existing company or not params[:channel_partner_id] present or not
  def create
    if params[:channel_partner_id].present?
      register_with_existing_company
    else
      register_with_new_company
    end
  end

  def add_user_account
    if params[:register_code].present?
      @user = User.where(register_in_cp_company_token: params[:register_code]).first
      @channel_partner = ChannelPartner.where(id: params[:channel_partner_id]).first
      unless @user.present?
        redirect_to root_path, alert: 'This link is expired. Please ask the channel partner to send request again'
      end
      unless @channel_partner.present?
        redirect_to root_path, alert: "#{ChannelPartner.model_name.human} not found"
      end
    else
      redirect_to root_path, alert: 'Registration code is missing'
    end
  end

  private

  def create_cp_user
    @user = User.new(permitted_attributes([:admin, User.new]))
    @user.assign_attributes(role: "cp_owner", booking_portal_client_id: current_client.id)
  end

  def handle_json_request
    @user = User.where(phone: params.dig(:user, :phone)).first
    create_cp_user unless @user

    if @user.persisted? || @user.save
      otp_sent_status = @user.send_otp
      if Rails.env.development?
        Rails.logger.info "---------------- #{@user.otp_code} ----------------"
      end
      if otp_sent_status[:status]
        format.json { render json: { user: @user.as_json(@user.ui_json) }, status: :created }
      else
        format.json { render json: {user: @user.as_json(@user.ui_json), errors: [otp_sent_status[:error]].flatten}, status: :created }
      end
    else
      format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def register_with_new_company
    @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
    @channel_partner.is_existing_company = false
    respond_to do |format|
      if @channel_partner.save
        format.json { render json: { channel_partner: @channel_partner }, status: :created }
      else
        format.json { render json: { errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def register_with_existing_company
    @channel_partner = ChannelPartner.where(id: params[:channel_partner_id]).first
    @user = User.where(id: params[:user_id]).first

    respond_to do |format|
      if @channel_partner && @user
        @user.assign_attributes(register_in_cp_company_token: SecureRandom.base58(24), temp_channel_partner: @channel_partner, event: 'pending_approval')
        @user.assign_attributes(user_permitted_attributes_for_existing_company_flow || {})

        if @user.save
          send_request_to_company_owner
          ExpireRegisterPartnerInExistingCompanyLinkWorker.perform_in(24.hours, @user.id.to_s)
          format.json { render json: { user: @user.as_json(@user.ui_json), message: 'Registration request sent to Company owner' }, status: :ok }
        else
          format.json { render json: { errors: @user.errors.full_messages.uniq }, status: :unprocessable_entity }
        end
      else
        format.json { render json: { errors: ['Channel Parnter Company or User not found'] }, status: :not_found }
      end
    end
  end

  def user_permitted_attributes_for_existing_company_flow
    params.require(:user).permit(:first_name, :last_name, :email) if params[:user].present?
  end

  def send_request_to_company_owner
    client = @user.booking_portal_client
    email_template = ::Template::EmailTemplate.where(name: "cp_user_register_in_company").first
    if email_template.present?
      email = Email.create!({
        booking_portal_client_id: client.id,
        body: ERB.new(client.email_header).result(binding) + email_template.parsed_content(@user) + ERB.new(client.email_footer).result(binding),
        subject: email_template.parsed_subject(@user),
        to: [ @channel_partner.primary_user&.email ],
        cc: client.notification_email.to_s.split(',').map(&:strip),
        triggered_by_id: @user.id,
        triggered_by_type: @user.class.to_s
      })
      email.sent!
    end
  end

end
