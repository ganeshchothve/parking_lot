module CpLeadActivityRegister
  def self.create_cp_lead_object(new_lead, lead, channel_partner)
    get_lead_data(lead)
    if new_lead
      new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "fresh_lead", lead_status: lead.lead_status, expiry_date: Date.today + 45, lead_id: lead.id, user_id: channel_partner.id)
    else
      if cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, channel_partner_id: channel_partner.id, expiry_date: {"$gt": Date.today}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "active_in_same_cp", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id)
      elsif cp_lead_activity = CpLeadActivity.where(lead_id: lead.id, expiry_date: {"$gt": Date.today}, channel_partner_id: {"$ne": channel_partner.id}).first
        new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id)
      elsif %w(lost unqualified).include?(lead.lead_stage)
        if lead.lead_lost_date + 15 > Date.today
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "count_given", lead_status: lead.lead_status, expiry_date: Date.today + 45, lead_id: lead.id, user_id: channel_partner.id)
        else
          if lead.sitevisit_date.present?
            new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id)
          else
            new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id)
          end
        end
      elsif lead.lead_stage == 'active'
        if lead.sitevisit_date.present?
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "no_count", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id)
        else
          new_cp_lead_activity = CpLeadActivity.new(registered_at: Date.today, count_status: "accompanied_credit", lead_status: lead.lead_status, expiry_date: Date.today - 1, lead_id: lead.id, user_id: channel_partner.id)
        end
      end
    end
  end

  def self.get_lead_data(lead)
    lead.lead_stage = "registered"
    lead.lead_status = "active"
    lead.lead_lost_date = nil
    lead.sitevisit_status = "conducted"
    lead.sitevisit_date = Date.today - 4
    lead.save
  end
end