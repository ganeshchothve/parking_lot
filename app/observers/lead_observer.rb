class LeadObserver < Mongoid::Observer
  def before_validation lead
    lead.email = lead.email.downcase
    lead.phone = Phonelib.parse(lead.phone).to_s if lead.phone.present?
  end

  def after_create lead
    lead.send_create_notification
  end

  def after_update lead
    # lead.send_update_notification if lead.stage_changed? && lead.stage.present?
  end
end
