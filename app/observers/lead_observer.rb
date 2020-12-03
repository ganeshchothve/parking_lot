class LeadObserver < Mongoid::Observer
  include ApplicationHelper

  def before_validation lead
    lead.email = lead.email.downcase
  end
end
