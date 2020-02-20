class CrmBaseObserver < Mongoid::Observer

  observe "Crm::Base"

  def before_validation base
    base.domain =  base.domain.downcase
    base.name = base.name.downcase
  end
end