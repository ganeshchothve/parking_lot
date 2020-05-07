class Admin::EmailPolicy < EmailPolicy

  def index?
    !user.buyer?
  end

  def monthly_count?
    user.role?('superadmin')
  end

  def show?
    if !user.buyer?
      if %[admin superadmin].include?(user.role)
        true
      else 
       record.recipient_ids.include?(user.id)
      end
    end
  end
end
