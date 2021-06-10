require 'net/http'
module FetchLeadData
  def self.get(selldo_lead_id, selldo_project_name, client)
    begin
      url =  ENV_CONFIG['selldo']['base_url'] + "/api/leads/get_lead.json?api_key=#{client.selldo_api_key}&client_id=#{client.selldo_client_id.to_s}&lead_id=#{selldo_lead_id}&consolidated_lead_data=true"
      uri = URI(url)
      response = JSON.parse(Net::HTTP.get(uri))
      interested_properties = (JWT.decode(response['data'], client.selldo_api_secret.to_s, 'HS256'))[0]['interested_properties'] rescue []
      interested_properties = interested_properties.map { |ip| ip['project_name']}
      # If not included send true
      !(interested_properties.include?(selldo_project_name))
    rescue => e
      Rails.logger.error("Error while Fetching the  : #{e.inspect}")
      'error'
    end
  end

  def self.fetch_notes(selldo_lead_id, client)
    begin
      url =  ENV_CONFIG['selldo']['base_url'] + "/client/leads/" + selldo_lead_id + "/activities.json?filters[_type]=Note&page=1&per_page=15&api_key=#{client.selldo_api_key}&client_id=#{client.selldo_client_id.to_s}"
      uri = URI(url)
      notes = JSON.parse(Net::HTTP.get(uri))['results']
      notes.map { |remark| remark unless remark['note']['content'].start_with?("Added BY(") }.compact
    rescue => e
      Rails.logger.error("Error while Fetching the notes : #{e.inspect}")
      []
    end
  end
end
