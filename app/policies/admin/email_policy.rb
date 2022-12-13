class Admin::EmailPolicy < EmailPolicy

  def index?
    out = !user.buyer?
    out && user.active_channel_partner?
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

  def resend_email?
    record.status == 'draft' && user.role?(:admin)
  end
end
