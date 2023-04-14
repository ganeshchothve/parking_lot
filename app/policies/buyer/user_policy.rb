class Buyer::UserPolicy < UserPolicy
  # def index? def resend_confirmation_instructions? def resend_password_instructions? def export? def confirm_via_otp? def print? def new? def create? def reactivate_account? def permitted_attributes def update_password? def update? def edit? from UserPolicy

  def show?
    false
  end

  def print?
    show?
  end

  def asset_create?
    record.id == user.id
  end

  def select_project
    user.buyer?
  end

  def select_projects
    user.buyer?
  end

  def show_lead_tagging?
    false
  end
end
