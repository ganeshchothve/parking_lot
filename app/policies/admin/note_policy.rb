class Admin::NotePolicy < NotePolicy

  def new?
    "Admin::#{record.notable_type}Policy".constantize.new(user, record.notable).update?
  end

  def create?
    "Admin::#{record.notable_type}Policy".constantize.new(user, record.notable).update?
  end
end
