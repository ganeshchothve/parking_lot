class BookingDetailPolicy < ApplicationPolicy
  
  # we allow only admin and user role people to access the update action for uploading files 
  def update?
    ['admin','user'].include?(user.role)
  end

  def permitted_attributes params={}
    [:TDS_Doc]
  end
end
