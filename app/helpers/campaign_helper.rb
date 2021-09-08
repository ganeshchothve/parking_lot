module CampaignHelper
  def custom_campaigns_path
    current_user.buyer? ? buyer_campaigns_path : admin_campaigns_path
  end

  def available_campaign_statuses campaign
    if campaign.new_record?
      [ 'Draft', 'draft' ]
    else
      statuses = campaign.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end
end