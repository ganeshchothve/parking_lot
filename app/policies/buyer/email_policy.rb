class Buyer::EmailPolicy < EmailPolicy

  def index?
    user.buyer?
  end

  def show?
     record.recipient_ids.include?(user.id)
  end
end
