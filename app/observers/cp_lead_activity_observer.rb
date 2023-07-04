class CpLeadActivityObserver < Mongoid::Observer
  def before_validation cp_lead_activity
    cp_lead_activity.email = cp_lead_activity.email&.downcase
    cp_lead_activity.phone = Phonelib.parse(cp_lead_activity.phone).to_s if cp_lead_activity.phone.present?
    cp_lead_activity.channel_partner_id = cp_lead_activity.user.channel_partner_id if cp_lead_activity.channel_partner_id.blank? && cp_lead_activity.user.present?
    #cp_lead_activity.cp_manager = cp_lead_activity.channel_partner&.manager if cp_lead_activity.cp_manager_id.blank? && cp_lead_activity.channel_partner
    #cp_lead_activity.cp_admin = cp_lead_activity.cp_manager&.manager if cp_lead_activity.cp_admin_id.blank? && cp_lead_activity.cp_manager
  end

  def before_save cp_lead_activity
    #cp_lead_activity.push_source_to_selldo
  end

  def before_create cp_lead_activity
  end
end
