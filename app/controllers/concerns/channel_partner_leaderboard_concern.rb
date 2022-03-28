module ChannelPartnerLeaderboardConcern
  extend ActiveSupport::Concern

  included do
    before_action :get_options, only: [:top_channel_partners_by_incentives, :highest_incentive_per_booking, :average_incentive_per_booking, :incentive_predictions, :achieved_target]
  end

  def channel_partners_leaderboard

  end

  def top_channel_partners_by_incentives
    @vis_options.merge!(query: get_query)
    @cp_rank_wise_data = CpIncentiveLeaderboardDataProvider.top_channel_partners(@vis_options)
    respond_to do |format|
      format.json { render json: @cp_rank_wise_data.as_json }
      format.html {}
      format.js
    end
  end

  def highest_incentive_per_booking
    @vis_options.merge!(query: get_query)
    @highest_incentive_per_booking_data = CpIncentiveLeaderboardDataProvider.highest_incentive_per_booking(@vis_options)
    respond_to do |format|
      format.json { render json: @highest_incentive_per_booking_data.as_json }
      format.html {}
      format.js
    end
  end

  def average_incentive_per_booking
    @vis_options.merge!(query: get_query)
    @average_incentive = CpIncentiveLeaderboardDataProvider.average_incentive_per_booking(@vis_options)
    respond_to do |format|
      format.json { render json: {average_incentive_per_booking: @average_incentive} }
      format.html {}
      format.js
    end
  end

  def incentive_predictions
    @vis_options.merge!(query: get_query)
    @incentive_predictions_data = CpIncentiveLeaderboardDataProvider.incentive_predictions(@vis_options)
    respond_to do |format|
      format.json { render json: @incentive_predictions_data.as_json }
      format.html {}
      format.js
    end
  end

  def achieved_target
    @vis_options.merge!(query: get_query)
    @achieved_target_data = CpIncentiveLeaderboardDataProvider.achieved_target(@vis_options)
    respond_to do |format|
      format.json { render json: @achieved_target_data.as_json }
      format.html {}
      format.js
    end
  end


  def get_query
    query = []
    query << {project_ids: {"$in": params[:project_ids]}} if params[:project_ids].present?
    query << {id: {"$in": params[:variable_incentive_scheme_ids]}} if params[:variable_incentive_scheme_ids].present?
    query
  end

  def get_options
    @vis_options = {}
    @vis_options.merge!(user_id: params[:user_id]) if params[:user_id].present?
    @vis_options.merge!(project_ids: params[:project_ids]) if params[:project_ids].present?
    if ["cp_owner", "channel_partner"].include?(current_user.role)
      @vis_options.merge!(user_id: current_user.id.to_s)
    end
  end
end