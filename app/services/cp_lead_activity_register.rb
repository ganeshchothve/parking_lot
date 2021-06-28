module CpLeadActivityRegister
  include ApplicationHelper
  extend ApplicationHelper
  extend LeadsHelper

  def self.create_cp_lead_object(lead, channel_partner, lead_details = {})
    lead = get_lead_data(lead, lead_details)
    if lead.new_record? && (lead_details.blank? || lead_details[:lead_already_exists] == 'false')
      new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "fresh_lead", lead_status: lead.lead_status, expiry_date: Date.current + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
    else
      if cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, user_id: channel_partner.id, expiry_date: {"$gt": Date.current}).first || CpLeadActivity.in(lead_id: Lead.nin(id: lead.id).where(lead_id: lead.lead_id).distinct(:id)).where(expiry_date: {"$gt": Date.current}).first
        new_cp_lead_activity =  if cp_lead_activity.user_id == channel_partner.id
                                  CpLeadActivity.new(registered_at: Date.current, count_status: "active_in_same_cp", lead_status: lead.lead_status, expiry_date: cp_lead_activity.expiry_date , lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
                                  # Note : Confirmed from client as it is ok if lead shown two times
                                  # if lead.project_id == cp_lead_activity.lead.project_id
                                  #   cp_lead_activity.expiry_date = (Date.current - 1)
                                  #   cp_lead_activity.save
                                  # end
                                  #activity
                                else
                                  site_visit_conditions_handled(lead, channel_partner, true)
                                end
      elsif cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, expiry_date: {"$gt": Date.current}, user_id: {"$ne": channel_partner.id}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.current - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
      elsif %w(lost unqualified).include?(lead.lead_stage)
        if ((Time.zone.parse(lead.lead_lost_date) rescue Date.current) + 15) < Date.current
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.current, count_status: "count_given", lead_status: lead.lead_status, expiry_date: Date.current + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        else
          new_cp_lead_activity = site_visit_conditions_handled(lead, channel_partner)
        end
      else
        new_cp_lead_activity = site_visit_conditions_handled(lead, channel_partner)
      end
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
