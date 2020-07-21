class Api::V1::ChannelPartnersController < ApisController
  before_action :authenticate_request
  before_action :set_channel_partner, except: :create
  before_action :reference_id_present?, only: :create

  #
  # The create action always creates a new channel partner from an external api request.
  #
  # POST  /api/v1/channel_partners
  #
  def create
    @channel_partner = ChannelPartner.new(channel_partner_create_params)
    update_third_party_references
    if @channel_partner.save
      render json: {id: @channel_partner.id, message: 'Channel Partner successfully created.'}, status: :created
    else
      render json: @channel_partner.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  #
  # The update action will update the details of an existing channel partner using the crm id and reference id  for identification.
  #
  # PATCH     /api/v1/channel_partners/:id
  #
  def update
    @channel_partner.assign_attributes(channel_partner_update_params)
    update_third_party_references
    if @channel_partner.save
      render json: { id: @channel_partner.id, message: 'Channel Partner successfully updated'}, status: :ok
    else
      render json: @channel_partner.errors.full_messages.uniq, status: :unprocessable_entity
    end
  end

  private


  # Checks if the reference-id is present. Reference-id is the external CRM identification id.
  def reference_id_present?
    render json: { message: 'Reference id is required to create Channel Partner' }, status: :bad_request unless params.dig(:channel_partner, :ids, :reference_id)
  end

  # Sets the channel partner object
  def set_channel_partner
    @channel_partner = ChannelPartner.where("third_party_references.crm_id": @crm.id, "third_party_references.reference_id": params.dig(:id)).first
    render json: { message: 'Channel Partner is not registered.' }, status: :not_found if @channel_partner.blank?
  end

  def update_third_party_references
    ids = params.dig(:channel_partner, :ids).try(:permit, ChannelPartner::THIRD_PARTY_REFERENCE_IDS)
    @channel_partner.update_external_ids(ids, @crm.id) if ids
  end

  # Allows only certain parameters to be saved.
  def channel_partner_create_params
    params.fetch(:channel_partner, {}).permit(:first_name, :last_name, :rera_id, :aadhaar, :pan_number, :company_name, :phone, :email)
  end

  # Allows only certain parameters to beupdated.
  def channel_partner_update_params
    params.fetch(:channel_partner, {}).permit(:first_name, :last_name, :rera_id, :aadhaar, :pan_number, :company_name)
  end
end
