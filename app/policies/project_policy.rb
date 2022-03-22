class ProjectPolicy < ApplicationPolicy

  def walk_in_enabled?
    record.walk_ins_enabled?
  end

end
