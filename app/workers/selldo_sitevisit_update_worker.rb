class SelldoSitevisitUpdateWorker
  include Sidekiq::Worker
  include ApplicationHelper

  def perform(lead_id, current_user_id, sitevisit_id, cp_code = nil)
    lead = Lead.where(id: lead_id).first
    current_user = User.where(id: current_user_id).first
    current_client = lead.user.booking_portal_client
    crm_base = Crm::Base.where(booking_portal_client_id: current_client.id ,domain: ENV_CONFIG.dig(:selldo, :base_url)).first
    sitevisit = lead.site_visits.where(id: sitevisit_id).first
    # v2.sell.do params
    # params = {
    #   api_key: "6a6854e70e4be582de82bf5c4861ab11",
    #   client_id: "587ddb2b5a9db31da9000002",
    #   user_email: current_user.email,
    #   "site_visit":
    #   {
    #     lead_crm_id: lead.lead_id,
    #     conducted_on: DateTime.now.to_s,
    #     agenda: "customer visited",
    #     sitevisit_type: "visit",
    #     notes: "update site visit through IRIS",
    #     project_id: "587dec4626300a3aca00001c",
    #     previous_sv_action: action,
    #   }
    # }
    if sitevisit
      if sitevisit.selldo_id.present?
        #  params = {
        #     api_key: current_client.selldo_api_key,
        #     client_id: current_client.selldo_client_id,
        #     "site_visit": {
        #       "project_id": current_client.selldo_project_id,
        #       "lead_crm_id": "3739",
        #       "status": "conducted",
        #       "conducted_on": DateTime.now,
        #       "notes": "Notes"
        #     }
        #   }
        # data = RestClient.put("https://v2.sell.do/client/leads/x/site_visits/#{sitevisit.selldo_id}.json", params)
        # response = JSON.parse(data)
      else #if cp_code.present?
        if (project = sitevisit.project) && project.selldo_api_key.present? && project.selldo_client_id.present? && project.selldo_id.present?
          params = {
            api_key: sitevisit.project.selldo_api_key,
            client_id: sitevisit.project.selldo_client_id,
            # user_email: current_user.email,
            "site_visit":
            {
              project_id: sitevisit.project.selldo_id,
              scheduled_on: sitevisit.scheduled_on.to_s,
              sitevisit_type: "visit",
              agenda: "",
              confirmed: "true",
              lead_crm_id: lead.lead_id,
              status: "scheduled",
              #custom_visit_owner: cp_code

            }
          }
          data = RestClient.post("#{ENV_CONFIG[:selldo][:base_url]}/client/leads/x/site_visits.json", params)
          response = JSON.parse(data)
          if response.present?
            lead.notes << Note.new(notable: lead, note: "Sitevisit #{response['site_visit']['status']}", creator: current_user)
            lead.save

            if crm_base.present?
              sitevisit.update_external_ids({reference_id: response.dig("site_visit", "_id")}, crm_base.id)
            else
              sitevisit.selldo_id = response.dig("site_visit", "_id")
              sitevisit.save
            end
          end
        end
      end
    end
    rescue StandardError => e
      Rails.logger.error I18n.t("worker.selldo.errors.sitevisit_update_failed", name1: lead.try(:name), name2: e.message)
  end
end
