module CpLeadActivityRegister
  include ApplicationHelper
  extend ApplicationHelper
  extend LeadsHelper

  def self.create_cp_lead_object(lead, channel_partner, lead_details = {})
    lead = get_lead_data(lead, lead_details)
    if lead.new_record? || lead.cp_lead_activities.where(user_id: channel_partner.id).blank?
      new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "fresh_lead", lead_status: lead.lead_status, expiry_date: Date.current + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
    end
    new_cp_lead_activity
  end

  def self.site_visit_conditions_handled(lead, channel_partner, is_lead_active = false)
    if is_lead_active || lead.sitevisit_date.present?
      CpLeadActivity.new(registered_at: Date.current, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
    else
      CpLeadActivity.new(registered_at: Date.current, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
    end
  end

  def self.get_lead_data(lead, lead_details = {})
    lead.lead_status =  lead_details[:lead_already_exists] == 'true' ? "already_exists" : "registered"
    lead.lead_stage = lead_details[:stage]
    lead.lead_lost_date = (Time.zone.parse(lead_details[:stage_changed_on]) rescue nil) if lead.lead_stage.in?(%w(lost unqualified))
    client = lead.user.booking_portal_client
    lead
  end
end
