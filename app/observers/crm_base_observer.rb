class CrmBaseObserver < Mongoid::Observer

  observe "Crm::Base"

  def before_validation base
    base.domain =  base.domain.downcase if base.domain
  end
end