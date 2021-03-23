module CpLeadActivityRegister
  def self.create_cp_lead_object(new_lead, is_interested_for_project, lead, channel_partner, lead_details = {})
    lead = get_lead_data(lead, lead_details)
    if new_lead && is_interested_for_project && !(%w(lost unqualified).include?(lead.lead_stage))
      new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "fresh_lead", lead_status: lead.lead_status, expiry_date: Date.current + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
    else
      if cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, user_id: channel_partner.id, expiry_date: {"$gt": Date.current}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "active_in_same_cp", lead_status: lead.lead_status, expiry_date: cp_lead_activity.expiry_date , lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        cp_lead_activity.expiry_date = Date.current - 1
        cp_lead_activity.save
      elsif cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, expiry_date: {"$gt": Date.current}, user_id: {"$ne": channel_partner.id}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
      elsif %w(lost unqualified).include?(lead.lead_stage)
        if (Time.zone.parse(lead.lead_lost_date) + 15) < Date.current
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "count_given", lead_status: lead.lead_status, expiry_date: Date.current + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        else
          if lead.sitevisit_date.present?
            new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
          else
            new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
          end
        end
      else
        if lead.sitevisit_date.present?
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        else
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        end
      end
    end
    new_cp_lead_activity.try(:save)
  end

  def self.get_lead_data(lead, lead_details = {})
    lead.lead_status =  lead_details[:lead_already_exists] == 'true' ? "already_exists" : "registered"
    lead.lead_stage = lead_details[:stage]
    lead.lead_lost_date = (Time.zone.parse(lead_details[:stage_changed_on]) rescue nil) if lead.lead_stage.in?(%w(lost unqualified))
    client = lead.user.booking_portal_client
    lead.sitevisit_date, lead.sitevisit_status = FetchLeadData.site_visit_status_and_date(lead.lead_id, client, lead.project.selldo_id.to_s)
    lead.remarks = FetchLeadData.fetch_notes(lead.lead_id, client)
    lead.save
    lead
  end
end
