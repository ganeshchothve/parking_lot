class Admin::SmsPolicy < SmsPolicy

  def index?
    !user.buyer?
  end

  def sms_pulse?
    user.role == 'superadmin'
  end

  def show?
    if !user.buyer?
      if %[admin superadmin].include?(user.role)
        true
      else 
        record.recipient_id == user.id
      end
    end
  end
end
