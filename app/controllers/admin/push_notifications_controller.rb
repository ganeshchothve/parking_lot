class Admin::PushNotificationsController < AdminController
  include PushNotificationConcern
  before_action :set_notification, only: :show #set_notification written in NotificationConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  # index defined in NotificationConcern
  # GET /admin/notifications

  # show defined in NotificationConcern
  # GET /admin/notifications/:id

  private


  def apply_policy_scope
    PushNotification.with_scope(policy_scope([:admin, Notification])) do
      yield
    end
  end

  def authorize_resource
    if %w(index).include?(params[:action])
      authorize [:admin, PushNotification]
    else
      authorize [:admin, @push_notification]
    end
  end
end
