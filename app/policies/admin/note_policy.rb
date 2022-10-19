class Admin::NotePolicy < NotePolicy

  def new?
    policy = "Admin::#{record.notable_type}Policy".constantize.new(user, record.notable)
    policy.respond_to?(:note_create?) ? policy.note_create? : policy.update?
  end

  def create?
    new?
  end

  def destroy?
    true
  end
end
