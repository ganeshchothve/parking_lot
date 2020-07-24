class Api::V1::ChannelPartnersController < ApisController
  before_action :set_channel_partner, except: :create
  before_action :reference_id_present?, only: :create

  #
  # The create action always creates a new channel partner from an external api request.
  #
  # POST  /api/v1/channel_partners
  #
  def create
    @channel_partner = ChannelPartner.new(channel_partner_create_params)
    if @channel_partner.save
      @channel_partner.update_external_ids(third_party_reference_params, @crm.id) if third_party_reference_params
      render json: {id: @channel_partner.id, message: 'Channel Partner successfully created.'}, status: :created
    else
      render json: {errors: @channel_partner.errors.full_messages.uniq}, status: :unprocessable_entity
    end
    rescue StandardError => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  #
  # The update action will update the details of an existing channel partner using the crm id and reference id  for identification.
  #
  # PATCH     /api/v1/channel_partners/:id
  #
  def update
    @channel_partner.assign_attributes(channel_partner_update_params)
    if @channel_partner.save
      @channel_partner.update_external_ids(third_party_reference_params, @crm.id) if third_party_reference_params
      render json: { id: @channel_partner.id, message: 'Channel Partner successfully updated'}, status: :ok
    else
      render json: {errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity
    end
    rescue StandardError => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private


  # Checks if the reference-id is present. Reference-id is the external CRM identification id.
  def reference_id_present?
    render json: { errors: ['Reference id is required to create Channel Partner'] }, status: :bad_request unless params.dig(:channel_partner, :ids, :reference_id)
  end

  # Sets the channel partner object
  def set_channel_partner
    @channel_partner = ChannelPartner.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig(:id)).first
    render json: { errors: ['Channel Partner is not registered.'] }, status: :not_found if @channel_partner.blank?
  end

  def third_party_reference_params
    params.dig(:channel_partner, :ids).try(:permit, ChannelPartner::THIRD_PARTY_REFERENCE_IDS)
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
    params.require(:channel_partner).permit(:first_name, :last_name, :rera_id, :aadhaar, :pan_number, :company_name, :phone, :email)
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
    params.require(:channel_partner).permit(:first_name, :last_name, :rera_id, :aadhaar, :pan_number, :company_name)
  end
end
