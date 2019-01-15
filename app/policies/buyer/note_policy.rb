class Buyer::NotePolicy < NotePolicy

  def create?
    "Buyer::#{record.notable_type}Policy".constantize.new(user, record.notable).update?
  end
end