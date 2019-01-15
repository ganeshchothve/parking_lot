class NotePolicy < ApplicationPolicy
  # Defined in child class
  # def create?
  # end

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

  def asset_create?
    create?
  end

  def permitted_attributes(_params = {})
    %i[id note note_type creator_id]
  end
end
