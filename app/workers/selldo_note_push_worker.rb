class SelldoNotePushWorker
  include Sidekiq::Worker

  def perform(selldo_lead_id, current_user_id, note)
    begin
      current_user = User.find current_user_id
      # Need a Updater key
      api_key = Client.selldo_api_clients.dig(:website, :api_key)
      params = {
        api_key: api_key,
        lead_id: selldo_lead_id,
        client_id: current_user.booking_portal_client.selldo_client_id,
        note: "Added BY(#{current_user.ds_name})" + ' => ' + note
      }
      RestClient.post(ENV_CONFIG['selldo']['base_url'] + "/api/leads/create.json", params)
    rescue => e
      Rails.logger.error("Error while Pushing note to sell.do : #{e.inspect}")
    end
  end
end