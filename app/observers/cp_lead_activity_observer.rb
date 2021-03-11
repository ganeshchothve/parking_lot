class CpLeadActivityObserver < Mongoid::Observer
  def after_create cp_lead_activity
    cp_lead_activity.push_source_to_selldo if cp_lead_activity.expiry_date >= Date.current
  end
end
