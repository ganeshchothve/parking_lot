class Admin::NotePolicy < NotePolicy
  def create?
    "Admin::#{record.notable_type}Policy".constantize.new(user, record.notable).update?
  end
end
