class NotePolicy < ApplicationPolicy
  def create?
    (record.notable_type + "Policy").constantize.new(user, record.notable).update?
  end

  def destroy?
    false
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
