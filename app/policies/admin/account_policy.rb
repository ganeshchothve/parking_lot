class Admin::AccountPolicy < AccountPolicy

  def index?
    current_client.enable_actual_inventory?(user) && %w[superadmin].include?(user.role)
  end

  def new?
    index?
  end

  def edit?
    index?
  end

  def show?
    index?
  end
  
  def destroy?
    index?
  end

  def permitted_attributes 
    attributes = [:account_number, :key, :secret, :by_default]
  end
end
