class Admin::TimeSlotPolicy < TimeSlotPolicy
  def index?
    if current_client.real_estate?
      %w[superadmin admin].include?(user.role)
    else
      false
    end
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    create? && record.allotted.to_i.zero?
  end

  def permitted_attributes params={}
    attrs = super
    attrs += [:date, :start_time, :end_time] if record.allotted.blank? || record.allotted&.zero?
    attrs += [:capacity]
    attrs
  end

end
