class CpLeadActivityObserver < Mongoid::Observer
  def before_save cp_lead_activity
    cp_lead_activity.push_source_to_selldo
  end
end
