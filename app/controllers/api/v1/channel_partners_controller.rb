class Api::V1::ChannelPartnersController < ApisController
  before_action :reference_ids_present?, :set_primary_user, only: :create
  before_action :set_channel_partner, except: :create
  before_action :add_third_party_reference_params #, :modify_params
  #
  # The create action always creates a new channel partner from an external api request.
  #
  # POST  /api/v1/channel_partners
  #
  def create
    unless ChannelPartner.reference_resource_exists?(@crm.id, params[:channel_partner][:reference_id])
      @channel_partner = ChannelPartner.new(channel_partner_create_params)
      @channel_partner.primary_user = @primary_user
      @channel_partner.is_existing_company = false
      if @channel_partner.save
        @channel_partner.approve! if @crm.user.booking_portal_client.try(:enable_direct_activation_for_cp?)
        render json: {channel_partner_id: @channel_partner.id, user_id: @channel_partner.primary_user.id ,message: I18n.t("controller.channel_partners.notice.created")}, status: :created
      else
        render json: {errors: @channel_partner.errors.full_messages.uniq}, status: :unprocessable_entity
      end
    else
      render json: {errors: ["Channel Partner with reference_id '#{params[:channel_partner][:reference_id]}' already exists"]}, status: :unprocessable_entity
    end
  end

  #
  # The update action will update the details of an existing channel partner using the crm id and reference id  for identification.
  #
  # PATCH     /api/v1/channel_partners/:reference_id
  #
  def update
    unless ChannelPartner.reference_resource_exists?(@crm.id, params[:channel_partner][:reference_id])
      @channel_partner.assign_attributes(channel_partner_update_params)
      if @channel_partner.save
        render json: {channel_partner_id: @channel_partner.id, user_id: @channel_partner.primary_user.id, message: I18n.t("controller.channel_partners.notice.updated")}, status: :ok
      else
        render json: {errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity
      end
    else
      render json: {errors: [I18n.t("controller.channel_partners.errors.already_exists", name: "#{params[:channel_partner][:reference_id]}")]}, status: :unprocessable_entity
    end
  end

  private


  # Checks if the required reference_id's are present. reference_id is the third party CRM resource id.
  def reference_ids_present?
    render json: { errors: [I18n.t("controller.channel_partners.errors.reference_id_required")] }, status: :bad_request and return unless params.dig(:channel_partner, :reference_id).present?
  end

  # Sets the channel partner object
  def set_channel_partner
    @channel_partner = ChannelPartner.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig(:id)).first
    render json: { errors: [I18n.t("controller.channel_partners.errors.not_registered")] }, status: :not_found if @channel_partner.blank?
  end

  def add_third_party_reference_params
    if cp_reference_id = params.dig(:channel_partner, :reference_id).presence
      # add third party references
      tpr_attrs = {
        crm_id: @crm.id.to_s,
        reference_id: cp_reference_id
      }
      if @channel_partner
        tpr = @channel_partner.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
        tpr_attrs[:id] = tpr.id.to_s if tpr
      end
      params[:channel_partner][:third_party_references_attributes] = [ tpr_attrs ]
    end
  end

  # Allows only certain parameters to be saved.
  # Example JSON for create
  # {
  #     "channel_partner":
  #     {
  #       "first_name": "Aakruti", #MANDATORY
  #       "last_name": "Shitut", #MANDATORY
  #       "email": "aakruti.shitut+cp2@sell.do", #MANDATORY
  #       "phone": "+918734142384", #MANDATORY
  #       "rera_id": "1231423134", #MANDATORY
  #       "aadhaar": "123417391236", #MANDATORY
  #       "pan_number": "AAAAC1214M",
  #       "company_name": "Amura",
  #       "ids": {
  #         "reference_id": "2" #MANDATORY
  #       }
  #     }
  # }
  def channel_partner_create_params
    params.require(:channel_partner).permit(:first_name, :last_name, :rera_id, :gstin_number, :aadhaar, :pan_number, :company_name, :phone, :email, :cp_code, :team_size, third_party_references_attributes: [:crm_id, :reference_id])
  end

  # Allows only certain parameters to beupdated.
  # Example JSON for create
  # {
  #     "channel_partner":
  #     {
  #       "first_name": "Aakruti", #MANDATORY
  #       "last_name": "Shitut", #MANDATORY
  #       "rera_id": "1231423134", #MANDATORY
  #       "aadhaar": "123417391236", #MANDATORY
  #       "pan_number": "AAAAC1214M",
  #       "company_name": "Amura"
  #     }
  # }
  def channel_partner_update_params
    params.require(:channel_partner).permit(:first_name, :last_name, :rera_id, :gstin_number, :aadhaar, :pan_number, :company_name, :cp_code, :team_size, third_party_references_attributes: [:id, :reference_id])
  end

  def set_primary_user
    @primary_user = User.new
    @primary_user.assign_attributes(user_params)
    @primary_user.assign_attributes(booking_portal_client_id: @crm.user.booking_portal_client_id)
  end

  def user_params
    params[:user] = {
      first_name: params.dig(:channel_partner, :first_name),
      last_name: params.dig(:channel_partner, :last_name),
      phone: params.dig(:channel_partner, :phone),
      email: params.dig(:channel_partner, :email),
      manager_id: params.dig(:channel_partner, :manager_id)
    }
    params[:channel_partner] = params[:channel_partner].except(:first_name, :last_name, :phone, :email)
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :manager_id)
  end

end
