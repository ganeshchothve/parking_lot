class Admin::LeadPolicy < LeadPolicy

  def index?
    !user.buyer?
  end

end
