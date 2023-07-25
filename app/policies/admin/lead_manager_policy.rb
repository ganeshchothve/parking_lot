class Admin::LeadManagerPolicy < LeadManagerPolicy
  def index?
    true
  end

  def update?
    false #%w(superadmin).include?(user.role)
  end

  def edit?
    update?
  end

  def extend_validity?
    %w(superadmin admin cp cp_admin sales_admin).include?(user.role) && record.active?
  end

  def update_extension?
    extend_validity?
  end

  def accompanied_credit?
    false#extend_validity?# && record.count_status == 'accompanied_credit'
  end

  def update_accompanied_credit?
    false#accompanied_credit?
  end

  def show?
    false
  end

  def asset_create?
    true
  end
end
