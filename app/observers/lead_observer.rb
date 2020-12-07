class LeadObserver < Mongoid::Observer

  def before_validation lead
    lead.email = lead.email.downcase
  end
end
