class CampaignObserver < Mongoid::Observer
  def before_validation campaign
    campaign.sources = campaign.campaign_budgets.collect{|x| x.source}
  end
end
