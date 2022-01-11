module ChannelPartnerRegisteration
  extend ActiveSupport::Concern

  def create
    if params[:channel_partner_id].present?
    else
      register_with_new_company
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

  private

  def get_query
    query = []
    query << {email: params[:channel_partner][:email]} if params.dig(:channel_partner, :email).present?
    query << {phone: params[:channel_partner][:phone]} if params.dig(:channel_partner, :phone).present?
    query
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

end