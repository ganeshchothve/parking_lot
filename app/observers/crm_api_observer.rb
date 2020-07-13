class CrmApiObserver < Mongoid::Observer

  observe "Crm::Api"

  def before_save api
    api.path = api.path.downcase
  end
end