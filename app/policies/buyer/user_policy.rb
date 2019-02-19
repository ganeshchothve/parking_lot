class Buyer::UserPolicy < UserPolicy
  # def index? def resend_confirmation_instructions? def resend_password_instructions? def export? def confirm_via_otp? def print? def new? def create? def permitted_attributes def update_password? def update? def edit? from UserPolicy

  def show?
    record.id == user.id
  end

  def print?
    show?
  end
end
