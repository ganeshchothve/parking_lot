class Buyer::SmsPolicy < SmsPolicy

  def index?
    user.buyer?
  end

  def show?
    record.recipient_id == user.id
  end
end
