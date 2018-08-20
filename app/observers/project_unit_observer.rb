class ProjectUnitObserver < Mongoid::Observer
  def before_validation project_unit
    project_unit.agreement_price = project_unit.calculate_agreement_price if project_unit.agreement_price.blank?
  end
  def before_save project_unit
    if project_unit.primary_user_kyc_id.blank? && project_unit.user_kyc_ids.present?
      project_unit.primary_user_kyc_id = project_unit.user_kyc_ids.first
    end
    if project_unit.primary_user_kyc_id.present? && project_unit.user_kyc_ids.present?
      project_unit.user_kyc_ids.reject!{|x| x == project_unit.primary_user_kyc_id}
    end
    if project_unit.status_changed? && ['hold', 'blocked', 'booked_tentative', 'booked_confirmed'].exclude?(project_unit.status)
      project_unit.user_id = nil
      project_unit.applied_discount_rate = 0
      project_unit.applied_discount_id = nil
    end
    if project_unit.status == 'available'
      project_unit.available_for = 'user'
    end
    if project_unit.status == 'employee'
      project_unit.available_for = 'employee'
    end
    if project_unit.status == 'management'
      project_unit.available_for = 'management'
    end
    if project_unit.status_changed? && project_unit.status == 'hold'
      project_unit.held_on = DateTime.now
      project_unit.applied_discount_rate = project_unit.discount_rate(project_unit.user)
      discount = project_unit.applicable_discount(project_unit.user)
      project_unit.applied_discount_id = discount.id if discount.present?
      ProjectUnitUnholdWorker.perform_in(project_unit.holding_minutes.minutes, project_unit.id.to_s)
      SelldoLeadUpdater.perform_async(project_unit.user_id.to_s)
    elsif project_unit.status_changed? && project_unit.status != 'hold'
      project_unit.held_on = nil
    end
    if project_unit.status_changed? && ['blocked', 'booked_tentative', 'booked_confirmed'].include?(project_unit.status) && ['available', 'hold'].include?(project_unit.status_was)
      project_unit.blocked_on = Date.today
      project_unit.auto_release_on = project_unit.blocked_on + project_unit.blocking_days.days
    end
    if project_unit.status != 'blocked' && project_unit.status != 'booked_tentative'
      project_unit.auto_release_on = nil
    end
  end

  def after_save project_unit
    BookingDetail.run_sync(project_unit.id, project_unit.changes)
    if project_unit.status_changed? && ["blocked", "booked_tentative", "booked_confirmed", "error"].include?(project_unit.status_was) && ["available", "employee", "management"].include?(project_unit.status)
      user_was = User.find(project_unit.user_id_was)
      project_unit.set(user_id: nil, blocked_on: nil, auto_release_on: nil, held_on: nil, primary_user_kyc_id: nil, user_kyc_ids: [])
      project_unit.receipts.where(status:"success").each{|x| x.project_unit_id = nil; x.status = "cancelled"; x.comments ||= ""; x.comments += " Cancelling as the unit (#{project_unit.name}) has been released."}

      if !project_unit.processing_user_request && !project_unit.processing_swap_request
        mailer = ProjectUnitMailer.released(user_was.id.to_s, project_unit.id.to_s)
        if Rails.env.development?
          mailer.deliver
        else
          mailer.deliver_later
        end

        Sms.create!(
          booking_portal_client_id: project_unit.booking_portal_client_id,
          recipient_id: user_was.id,
          sms_template_id: SmsTemplate.find_by(name: "project_unit_released").id,
          triggered_by_id: user_was.id,
          triggered_by_type: user_was.class.to_s
        )
      end
    end
  end

  def after_update project_unit
    if project_unit.status_changed? && ['blocked', 'booked_tentative', 'booked_confirmed'].include?(project_unit.status)
      mailer = ProjectUnitMailer.send(project_unit.status, project_unit.id.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        # SelldoInventoryPusher.perform_async(project_unit.status, project_unit.id.to_s, Time.now.to_i)
        mailer.deliver_later
      end
      user = project_unit.user
      if ['blocked', 'booked_tentative'].include?(project_unit.status) && ['available', 'hold'].include?(project_unit.status_was)
        Sms.create!(
          booking_portal_client_id: project_unit.booking_portal_client_id,
          recipient_id: user.id,
          sms_template_id: SmsTemplate.find_by(name: "project_unit_blocked").id,
          triggered_by_id: project_unit.id,
          triggered_by_type: project_unit.class.to_s
        )
      elsif project_unit.status == "booked_confirmed"
        Sms.create!(
          booking_portal_client_id: project_unit.booking_portal_client_id,
          recipient_id: user.id,
          sms_template_id: SmsTemplate.find_by(name: "project_unit_booked_confirmed").id,
          triggered_by_id: project_unit.id,
          triggered_by_type: project_unit.class.to_s
        )
      end
    end

    if project_unit.auto_release_on_changed? && project_unit.auto_release_on.present? && project_unit.auto_release_on_was.present?
      mailer = ProjectUnitMailer.auto_release_on_extended(project_unit.id.to_s, project_unit.auto_release_on_was.to_s)
      if Rails.env.development?
        mailer.deliver
      else
        mailer.deliver_later
      end
      if Rails.env.development?
        ::SMSWorker.new.perform("", "")
      else
        ::SMSWorker.perform_async("", "")
      end
    end
  end
end
