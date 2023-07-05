class Admin::LeadManagerPolicy < LeadManagerPolicy
  def index?
    true
  end

  def update?
    %w(superadmin).include?(user.role)
  end

  def edit?
    update?
  end

  def extend_validity?
    %w(admin cp_admin).include?(user.role) && record.can_extend_validity? && record.count_status != 'no_count'
  end

  def update_extension?
    extend_validity?
  end

  def accompanied_credit?
    extend_validity? && record.count_status == 'accompanied_credit'
  end

  def update_accompanied_credit?
    accompanied_credit?
  end

  def show?
    true
  end

  def asset_create?
    true
  end
end
