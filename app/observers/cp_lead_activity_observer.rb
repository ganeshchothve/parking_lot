class CpLeadActivityObserver < Mongoid::Observer
  def before_validation cp_lead_activity
    cp_lead_activity.cp_manager = cp_lead_activity.channel_partner&.manager if cp_lead_activity.cp_manager_id.blank? && cp_lead_activity.channel_partner
    cp_lead_activity.cp_admin = cp_lead_activity.cp_manager&.manager if cp_lead_activity.cp_admin_id.blank? && cp_lead_activity.cp_manager
  end

  def before_save cp_lead_activity
    cp_lead_activity.push_source_to_selldo
  end

  def before_create cp_lead_activity
    lead = cp_lead_activity.lead
    lead.manager_id = cp_lead_activity.user_id
    lead.channel_partner_id = cp_lead_activity.channel_partner_id
    lead.cp_manager_id = cp_lead_activity.cp_manager_id
    lead.cp_admin_id = cp_lead_activity.cp_admin_id
    lead.referenced_manager_ids << cp_lead_activity.user_id
    lead.referenced_manager_ids.uniq!
    lead.save
  end

  def after_create cp_lead_activity
    lead = cp_lead_activity.lead
    if lead.booking_portal_client.is_mp_client? && lead.crm_reference_id(ENV_CONFIG.dig(:kylas, :base_url)).blank?
      Kylas::CreateDeal.new(lead.user, lead, {run_in_background: false}).call
    end
  end
end
