class LeadObserver < Mongoid::Observer

  def after_create lead
    lead.send_create_notification
  end

  def after_update lead
    lead.send_update_notification if lead.stage_changed?
  end
end
