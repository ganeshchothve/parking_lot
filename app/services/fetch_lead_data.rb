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

  def self.site_visit_status_and_date(selldo_lead_id, client, selldo_project_id)
    response = self.fetch_site_visits(selldo_lead_id, client)
    site_visits = response['results'].select { |sv| (sv['site_visit']['project_id'] == selldo_project_id) && (%w[scheduled conducted].include?(sv['site_visit']['status'])) }
    if site_visits.blank?
      [nil, nil]
    else
      site_visit = site_visits.select { |sv| sv['site_visit']['status'] == 'conducted' }[0]
      if site_visit.present?
        [site_visit['site_visit']['conducted_on'], site_visit['site_visit']['status']]
      else
        site_visit = site_visits.select { |sv| sv['site_visit']['status'] == 'scheduled' }[0]
        site_visit.present? ? [site_visit['site_visit']['scheduled_on'], site_visit['site_visit']['status']] : [nil, nil]
      end
    end
  end

  def self.fetch_site_visits(selldo_lead_id, client)
    begin
      url =  ENV_CONFIG['selldo']['base_url'] + "/client/leads/" + selldo_lead_id + "/activities.json?filters[_type]=SiteVisit&page=1&per_page=15&api_key=#{client.selldo_api_key}&client_id=#{client.selldo_client_id.to_s}"
      uri = URI(url)
      JSON.parse(Net::HTTP.get(uri))
    rescue => e
      Rails.logger.error("Error while Fetching the site_visits : #{e.inspect}")
      []
    end
  end

  def self.fetch_notes(selldo_lead_id, client)
    begin
      url =  ENV_CONFIG['selldo']['base_url'] + "/client/leads/" + selldo_lead_id + "/activities.json?filters[_type]=Note&page=1&per_page=15&api_key=#{client.selldo_api_key}&client_id=#{client.selldo_client_id.to_s}"
      uri = URI(url)
      notes = JSON.parse(Net::HTTP.get(uri))['results']
      notes.map { |remark| remark unless remark['note']['content'].start_with?("Added BY(") }.compact
    rescue => e
      Rails.logger.error("Error while Fetching the site_visits : #{e.inspect}")
      []
    end
  end
end
