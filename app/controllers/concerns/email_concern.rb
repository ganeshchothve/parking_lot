module EmailConcern
  extend ActiveSupport::Concern

  def set_email
    @email = Email.find(params[:id])
  end
end
