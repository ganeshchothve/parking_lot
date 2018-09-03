class ExternalInventoryViewConfigPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :provider, :status, :url, :_destroy]
  end
end
