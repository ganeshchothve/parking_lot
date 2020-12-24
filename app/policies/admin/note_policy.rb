class Admin::NotePolicy < NotePolicy

  def new?
    "Admin::#{record.notable_type}Policy".constantize.new(user, record.notable).update?
  end

  def create?
    policy = "Admin::#{record.notable_type}Policy".constantize.new(user, record.notable)
    policy.respond_to?(:note_create?) ? policy.note_create? : policy.update?
  end
end
