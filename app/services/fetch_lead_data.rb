require 'net/http'
module FetchLeadData
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
      url =  ENV_CONFIG['selldo']['base_url'] + "/client/leads/" + selldo_lead_id + "/activities.json?filters[_type]=Note&page=1&per_page=5&api_key=#{client.selldo_api_key}&client_id=#{client.selldo_client_id.to_s}"
      uri = URI(url)
      JSON.parse(Net::HTTP.get(uri))['results']
    rescue => e
      Rails.logger.error("Error while Fetching the site_visits : #{e.inspect}")
      []
    end
  end
end
