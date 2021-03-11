class Admin::Users::NotificationsController < AdminController
  before_action :set_user
  before_action :authorize_resource

  private
  
  def authorize_resource
    if %w(index).include?(params[:action])
      authorize [:admin, Notification]
    else
      authorize [:admin, @notification]
    end
  end
end
