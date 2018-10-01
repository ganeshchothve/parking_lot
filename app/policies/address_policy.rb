class AddressPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :address1, :address2, :city, :state, :country, :country_code, :zip, :primary, :address_type, :_destroy]
  end
end
