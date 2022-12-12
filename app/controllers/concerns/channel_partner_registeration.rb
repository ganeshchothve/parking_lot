module ChannelPartnerRegisteration
  extend ActiveSupport::Concern

  def find_or_create_cp_user
    respond_to do |format|
      if request.format.json?
        handle_json_request(format)
      else
        create_cp_user
        if @user.save
          format.html { redirect_to new_user_session_path, notice: I18n.t("controller.channel_partners.notice.registered") }
        else
          format.html { redirect_to new_channel_partner_path, alert: @user.errors.full_messages }
        end
      end
    end
  end

  # New API for mobile apps, after separating login & register screens
  def register_cp_user
    respond_to do |format|
      if request.format.json?
        create_cp_user
        if @user.save
          send_otp
          format.json { render 'channel_partners/register.json', status: :created }
        else
          format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
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
      @user = User.where(booking_portal_client_id: current_client.id, register_in_cp_company_token: params[:register_code]).first
      @channel_partner = ChannelPartner.where(id: params[:channel_partner_id]).first
      unless @user.present?
        redirect_to root_path, alert: I18n.t("controller.channel_partners.errors.link_expired")
      end
      unless @channel_partner.present?
        redirect_to root_path, alert: "#{ChannelPartner.model_name.human} not found"
      end
    else
      redirect_to root_path, alert: I18n.t("controller.channel_partners.errors.code_missing")
    end
  end

  def add_cp_company
    @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
    @channel_partner.assign_attributes(is_existing_company: false, primary_user: @user, booking_portal_client: @user.booking_portal_client)
    @channel_partner.project_ids << current_project.id.to_s if current_project.present?
    respond_to do |format|
      if @channel_partner.save
        #auto approve partner company if flag on client is enabled
        @channel_partner.approve!
        format.html { redirect_to channel_partners_path, notice: 'Partner Company Successfully Created' }
        format.json { render json: @channel_partner, status: :created }
      else
        format.html { redirect_to channel_partners_path, alert: @channel_partner.errors.full_messages }
        format.json { render json: { errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private

  def create_cp_user
    @user = User.new(permitted_attributes([:admin, User.new]))
    @user.assign_attributes(role: "channel_partner", booking_portal_client_id: current_client.id, manager_id: params.dig(:user, :manager_id))
  end

  def handle_json_request(format)
    @user = User.where(booking_portal_client_id: current_client.try(:id), phone: params.dig(:user, :phone)).first
    create_cp_user unless @user

    if @user.persisted? || @user.save
      send_otp
      format.json { render 'channel_partners/register.json', status: :created }
    else
      format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def send_otp
    @otp_sent_status = @user.send_otp
    if Rails.env.development?
      Rails.logger.info "---------------- #{@user.otp_code} ----------------"
    end
  end

  def register_with_new_company
    @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))
    @channel_partner.is_existing_company = false
    @channel_partner.booking_portal_client = current_client
    @channel_partner.project_ids << current_project.id.to_s if current_project.present?
    respond_to do |format|
      if @channel_partner.save
        @channel_partner.approve! if current_client.enable_direct_activation_for_cp?
        format.json { render 'channel_partners/register_with_new_company.json', status: :created }
      else
        format.json { render json: { errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def register_with_existing_company
    @channel_partner = ChannelPartner.where(booking_portal_client_id: current_client.id, id: params[:channel_partner_id]).first
    @user = User.where(id: params[:user_id], booking_portal_client_id: current_client.id).first

    respond_to do |format|
      if @channel_partner && @user
        @user.assign_attributes(register_in_cp_company_token: SecureRandom.base58(24), temp_channel_partner: @channel_partner, event: 'pending_approval')
        @user.assign_attributes(user_permitted_attributes_for_existing_company_flow || {})

        if @user.save
          send_request_to_company_owner if current_client.base_domain.present?
          ExpireRegisterPartnerInExistingCompanyLinkWorker.perform_in(24.hours, @user.id.to_s)
          format.json { render 'channel_partners/register_with_existing_company.json', status: :ok }
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
    email_template = ::Template::EmailTemplate.where(booking_portal_client_id: current_client.try(:id), name: "cp_user_register_in_company").first
    if email_template.present?
      email = Email.create!({
        booking_portal_client_id: client.id,
        subject: email_template.parsed_subject(@user),
        to: [ @channel_partner.primary_user&.email ],
        cc: client.notification_email.to_s.split(',').map(&:strip),
        email_template_id: email_template.id,
        triggered_by_id: @user.id,
        triggered_by_type: @user.class.to_s
      })
      email.sent!
    end
    sms_template = Template::SmsTemplate.where(booking_portal_client_id: current_client.try(:id), name: "cp_user_register_in_company").first
    if sms_template.present?
      if @user.phone.present?
        Sms.create!(
          booking_portal_client_id: client.id,
          to: [@user.phone],
          sms_template_id: sms_template.id,
          triggered_by_id: @user.id,
          triggered_by_type: @user.class.to_s
        )
      end
    end
  end

end
