class ProjectUnitMailer < ApplicationMailer

  def blocked(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@project_unit.booking_portal_client.notification_email]
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Unit No.  #{@project_unit.name} has been blocked!")
  end

  def booked_tentative(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    # CC Removed as per the QA/Supriya Mam
    # cc = @cp.present? ? [@cp.email] : []
    # cc +project_unit.= current_client.notification_email
    make_bootstrap_mail(to: @user.email, subject: "Unit #{@project_unit.name} booked tentative")# cc: cc
  end

  def booked_confirmed(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@project_unit.booking_portal_client.notification_email]
    attachments["Allotment.pdf"] = WickedPdf.new.pdf_from_string(
      render_to_string(pdf: "allotment", template: "project_unit_mailer/send_allotment_letter.pdf.erb")
    )
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Congratulations on booking your home! ") #Unit #{@project_unit.name} booked confirmed
  end

  def auto_release_on_extended(project_unit_id, auto_release_on_was)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @auto_release_on_was = auto_release_on_was
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@project_unit.booking_portal_client.notification_email]
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Received an extension to hold the unit")
  end

  def released(user_id, project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = User.find(user_id) # This is not the user available on project_unit.user; which has already been set to nil
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += [@project_unit.booking_portal_client.notification_email]
    make_bootstrap_mail(to: @user.email, cc: cc, subject: "Unit #{@project_unit.name} has been released")
  end
end
