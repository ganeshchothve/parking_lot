class Buyer::CampaignsController < BuyerController
  include CampaignsConcern

  before_action :authenticate_user!
  before_action :set_campaign, only: %i[show edit update]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: %i[index]

  layout :set_layout
end
