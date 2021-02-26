module CpLeadActivityRegister
  def self.create_cp_lead_object(new_lead, lead, channel_partner, lead_details = {})
    get_lead_data(lead, lead_details)
    if new_lead && lead_details[:lead_already_exists] == 'false'
      new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "fresh_lead", lead_status: lead.lead_status, expiry_date: Date.today + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
    else
      if cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, user_id: channel_partner.id, expiry_date: {"$gt": Date.today}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "active_in_same_cp", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
      elsif cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, expiry_date: {"$gt": Date.today}, channel_partner_id: {"$ne": channel_partner.id}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
      elsif %w(lost unqualified).include?(lead.lead_stage)
        if lead.lead_lost_date + 15 > Date.today
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "count_given", lead_status: lead.lead_status, expiry_date: Date.today + 45, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        else
          if lead.sitevisit_date.present?
            new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
          else
            new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
          end
        end
      elsif lead.lead_status == 'already_exists'
        if lead.sitevisit_date.present?
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        else
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id, sitevisit_status: lead.sitevisit_status, sitevisit_date: lead.sitevisit_date)
        end
      end
    end
    new_cp_lead_activity.try(:save)
  end

  def self.get_lead_data(lead, lead_details = {})
    lead.lead_status =  lead_details[:lead_already_exists] == 'true' ? "already_exists" : "registered"
    lead.lead_stage = lead_details[:stage]
    lead.lead_lost_date = (Time.zone.parse(lead_details[:stage_changed_on]) rescue nil) if lead.lead_stage.in?(%w(lost unqualified))
    if lead_details[:last_sv_conducted_on].present?
      lead.sitevisit_status = "conducted"
      lead.sitevisit_date = (Time.zone.parse(lead_details[:last_sv_conducted_on]) rescue nil)
    end
    lead.save
  end
end