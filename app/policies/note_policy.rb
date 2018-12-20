class NotePolicy < ApplicationPolicy
  def create?
    (current_user_role_group.to_s + "::" + record.notable_type + "Policy").constantize.new(user, record.notable).update?
  end

  def destroy?
    false
  end

  def new?
    true
  end

  def show?
    true
  end

  def edit?
    false
  end

  def index?
    true
  end

  def permitted_attributes params={}
    [ :id, :note, :note_type, :creator_id ]
  end
end
