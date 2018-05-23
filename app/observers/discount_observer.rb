class DiscountObserver < Mongoid::Observer
  def before_save discount
    if discount.status_changed? && discount.status == 'approved'
      discount.approved_at = Time.now
    end
  end

  def after_save discount
    ApplicationLog.log("discount_updated", {
      discount_id: discount.id,
      status: discount.status,
      project_id: discount.project_id,
      project_tower_id: discount.project_tower_id,
      project_unit_id: discount.project_unit_id,
      user_id: discount.user_id,
      user_role: discount.user_role,
      value: discount.value,
      approved_at: discount.approved_at,
      approved_by: discount.approved_by
    }, RequestStore.store[:logging])

    if discount.status_changed?
      case discount.status
      when 'draft'
        User.where(role: 'admin').distinct(:id).each do |user_id|
          mailer = DiscountMailer.send_draft(discount.id.to_s, user_id.to_s)
          if Rails.env.development?
            mailer.deliver
          else
            mailer.deliver_later
          end
        end
      when 'approved'
        mailer = DiscountMailer.send_approved(discount.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      when 'disabled'
        mailer = DiscountMailer.send_disabled(discount.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end
      end
    end
  end
end
