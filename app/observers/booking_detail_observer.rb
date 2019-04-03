class BookingDetailObserver < Mongoid::Observer
  def before_create(booking_detail)
    booking_detail.name = "#{booking_detail.project_unit.name}  (#{booking_detail.project_unit.blocked_on})"
  end

  def after_create(booking_detail)
    booking_detail.send_notification!
  end

  def after_save(booking_detail)
    if booking_detail.status_changed?
      SelldoLeadUpdater.perform_async(booking_detail.user_id.to_s)
    end
  end

  # TODO:: Need to move in state machine callback
  def after_create booking_detail
    if booking_detail.hold?
      booking_detail.project_unit.set(status: 'hold', held_on: DateTime.now)
      ProjectUnitUnholdWorker.perform_in(booking_detail.project_unit.holding_minutes.minutes, booking_detail.project_unit_id.to_s)
    end
  end

  def after_update booking_detail
    project_unit = booking_detail.project_unit
    if booking_detail.project_unit.booking_portal_client.email_enabled?
        attachments_attributes = []
        if booking_detail.status == "booked_confirmed"
          action_mailer_email = ApplicationMailer.test(body: project_unit.booking_portal_client.templates.where(_type: "Template::AllotmentLetterTemplate").first.parsed_content(project_unit))

          pdf = WickedPdf.new.pdf_from_string(action_mailer_email.html_part.body.to_s)
          File.open("#{Rails.root}/allotment_letter-#{project_unit.name}.pdf", "wb") do |file|
            file << pdf
          end
          attachments_attributes << {file: File.open("#{Rails.root}/allotment_letter-#{project_unit.name}.pdf")}
        end

        Email.create!({
          booking_portal_client_id: project_unit.booking_portal_client_id,
          email_template_id: Template::EmailTemplate.find_by(name: "project_unit_#{project_unit.status}").id,
          cc: [project_unit.booking_portal_client.notification_email],
          recipients: [user],
          cc_recipients: (user.manager_id.present? ? [user.manager] : []),
          triggered_by_id: project_unit.id,
          triggered_by_type: project_unit.class.to_s,
          attachments_attributes: attachments_attributes
        })
      end
      if project_unit.booking_portal_client.sms_enabled?
        if ['blocked', 'booked_tentative'].include?(booking_detail.status) && booking_detail.status_changed?
          Sms.create!(
            booking_portal_client_id: project_unit.booking_portal_client_id,
            recipient_id: user.id,
            sms_template_id: Template::SmsTemplate.find_by(name: "project_unit_blocked").id,
            triggered_by_id: project_unit.id,
            triggered_by_type: project_unit.class.to_s
          )
        elsif booking_detail.status == "booked_confirmed"
          Sms.create!(
            booking_portal_client_id: user.booking_portal_client_id,
            recipient_id: user.id,
            sms_template_id: Template::SmsTemplate.find_by(name: "project_unit_booked_confirmed").id,
            triggered_by_id: project_unit.id,
            triggered_by_type: project_unit.class.to_s
          )
        end
      end
    end
end
