class ProjectUnitMailer < ApplicationMailer

  def blocked(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Unit No.  #{@project_unit.name} has been blocked!")
  end

  def booked_tentative(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    # CC Removed as per the QA/Supriya Mam
    # cc = @cp.present? ? [@cp.email] : []
    # cc += default_team
    # cc += crm_team
    mail(to: @user.email, subject: "Unit #{@project_unit.name} booked tentative")# cc: cc
  end

  def send_revised_letter(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    attachments["Allotment.pdf"] = WickedPdf.new.pdf_from_string(
    render_to_string(pdf: "allotment", template: "project_unit_mailer/send_allotment_letter.pdf.erb"))
    #Removed by Ashish
    #attachments["Welcome.pdf"] = WickedPdf.new.pdf_from_string(
    #render_to_string(pdf: "allotment", template: "dashboard/welcome.pdf.erb"))
    mail(to: @user.email, cc: cc, subject: "Revised Allotment Letter") #Unit #{@project_unit.name} booked confirmed
  end

  def booked_confirmed(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    attachments["Allotment.pdf"] = WickedPdf.new.pdf_from_string(
      render_to_string(pdf: "allotment", template: "project_unit_mailer/send_allotment_letter.pdf.erb"))
    #Removed by Ashish
    #attachments["Welcome.pdf"] = WickedPdf.new.pdf_from_string(
      #render_to_string(pdf: "allotment", template: "dashboard/welcome.pdf.erb"))
    mail(to: @user.email, cc: cc, subject: "Congratulations on booking your home! ") #Unit #{@project_unit.name} booked confirmed
  end

  def auto_release_on_extended(project_unit_id, auto_release_on_was)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @auto_release_on_was = auto_release_on_was
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Received an extension to hold the unit")
  end

  def released(user_id, project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = User.find(user_id) # This is not the user available on project_unit.user; which has already been set to nil
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Unit #{@project_unit.name} has been released")
  end

  def send_allotment_letter(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Provisional Allotment of Apartment! ")
  end

  def swap_request(project_unit_id, alternate_project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @alternate_project_unit = ProjectUnit.find(alternate_project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Swap request")
  end
end
