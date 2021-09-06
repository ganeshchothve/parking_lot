module CampaignsConcern
  extend ActiveSupport::Concern

  #
  # This is the index action for admin, users where they can view all the campaigns.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @campaigns = Campaign.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to admin_campaign_path(params[:fltrs][:_id])
    else
      @campaigns = @campaigns.paginate(page: params[:page] || 1, per_page: params[:per_page])
    end
    render 'campaigns/index'
  end

  #
  # This show action for admin, users where they can view details of a particular campaigns.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
    render 'campaigns/show'
  end

  def update
    attrs = permitted_attributes([current_user_role_group, @campaign])
    @campaign.assign_attributes(attrs)
    
    respond_to do |format|
      if (params.dig(:campaign, :event).present? ? @campaign.send("#{params.dig(:campaign, :event)}!") : @campaign.save)
        json = @campaign.as_json
        format.json { render json: json.to_json }
      else
        format.json { render json: { errors: @campaign.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private
  def authorize_resource
    if params[:action] == 'index' || params[:action] == 'export'
      authorize [:admin, Campaign]
    elsif params[:action] == 'new'
      authorize [:admin, Campaign.new]
    elsif params[:action] == 'create'
      authorize [:admin, Campaign.new(permitted_attributes([:admin, Campaign.new]))]
    else
      authorize [:admin, @campaign]
    end
  end

  def apply_policy_scope
    custom_scope = Campaign.where(Campaign.user_based_scope(current_user, params))
    Campaign.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end
