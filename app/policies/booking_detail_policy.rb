class BookingDetailPolicy < ApplicationPolicy
  
  # we allow only admin and user role people to access the update action for uploading files 
  def update?
    ['admin','user'].include?(user.role)
  end

  def permitted_attributes params={}
    [:tds_doc]
  end
end
