class CpLeadActivityObserver < Mongoid::Observer
  def before_save cp_lead_activity
    cp_lead_activity.push_source_to_selldo
  end

  def before_create cp_lead_activity
    lead = cp_lead_activity.lead
    lead.manager_id = cp_lead_activity.user_id
    lead.referenced_manager_ids << cp_lead_activity.user_id
    lead.referenced_manager_ids.uniq!
    lead.save
  end
end
