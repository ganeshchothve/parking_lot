class Admin::CampaignsController < AdminController
  include CampaignsConcern

  before_action :authenticate_user!
  before_action :set_campaign, only: %i[show edit update]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  layout :set_layout

  def edit
    render layout: false
  end

  def new
    @campaign = Campaign.new
    render layout: false
  end

  def create
    @campaign = Campaign.new
    @campaign.assign_attributes(permitted_attributes([current_user_role_group, @campaign]))
    @campaign.creator = current_user
    
    respond_to do |format|
      if @campaign.save
        format.html { redirect_to admin_campaigns_path, notice: I18n.t("controller.campaigns.notice.created") }
        format.json { render json: @campaign, status: :created }
      else
        errors = @campaign.errors.full_messages
        errors << @campaign.campaign_slabs.collect{|x| x.errors.full_messages}
        errors.flatten!
        format.html { render :new }
        format.json { render json: { errors: errors.uniq }, status: :unprocessable_entity }
      end
    end
  end
end
