module ChannelPartnerLeaderboardConcern
  extend ActiveSupport::Concern

  def top_channel_partners_by_incentives
    @cp_rank_wise_data = CpIncentiveLeaderboardDataProvider.top_channel_partners
    respond_to do |format|
      format.json { render json: @cp_rank_wise_data.as_json }
      format.html {}
    end
  end
end