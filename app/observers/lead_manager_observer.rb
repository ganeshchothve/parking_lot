class LeadManagerObserver < Mongoid::Observer
  def before_validation lead_manager
    lead_manager.email = lead_manager.email&.downcase
    lead_manager.phone = Phonelib.parse(lead_manager.phone).to_s if lead_manager.phone.present?
    lead_manager.user_id = lead_manager.lead.user_id if lead_manager.user_id.blank? && lead_manager.lead.present?
    lead_manager.channel_partner_id = lead_manager.manager.channel_partner_id if lead_manager.manager.present? && lead_manager.manager.channel_partner? && lead_manager.channel_partner_id.blank?
    #lead_manager.cp_manager = lead_manager.channel_partner&.manager if lead_manager.cp_manager_id.blank? && lead_manager.channel_partner
    #lead_manager.cp_admin = lead_manager.cp_manager&.manager if lead_manager.cp_admin_id.blank? && lead_manager.cp_manager
  end

  def before_save lead_manager
    #lead_manager.push_source_to_selldo
  end

  def before_create lead_manager
  end
end
