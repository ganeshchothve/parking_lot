class ProjectUnitMailer < ApplicationMailer

  def blocked(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Unit #{@project_unit.name} blocked")
  end

  def booked_tentative(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Unit #{@project_unit.name} booked tentative")
  end

  def booked_confirmed(project_unit_id)
    @project_unit = ProjectUnit.find(project_unit_id)
    @user = @project_unit.user
    @cp = @user.channel_partner
    cc = @cp.present? ? [@cp.email] : []
    cc += default_team
    cc += crm_team
    mail(to: @user.email, cc: cc, subject: "Unit #{@project_unit.name} booked confirmed")
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
end