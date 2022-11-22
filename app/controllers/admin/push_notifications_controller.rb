class Admin::PushNotificationsController < AdminController
  include PushNotificationConcern
  before_action :set_notification, only: [:new, :show, :create] #set_notification written in NotificationConcern
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  # index defined in NotificationConcern
  # GET /admin/notifications

  # show defined in NotificationConcern
  # GET /admin/notifications/:id

  def new
    render layout: false
  end

  def create
    @push_notification.assign_attributes(permitted_attributes([:admin, @push_notification]))
    @push_notification.booking_portal_client_id = current_client.try(:id)
    respond_to do |format|
      if @push_notification.save
        format.html { redirect_to admin_push_notifications_path, notice: I18n.t("controller.push_notifications.notice.notifications_sent") }
        format.json { render json: @push_notification, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @push_notification.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private


  # def apply_policy_scope
  #   PushNotification.with_scope(policy_scope([:admin, PushNotification])) do
  #     yield
  #   end
  # end

  def authorize_resource
    if %w(index new).include?(params[:action])
      authorize [:admin, PushNotification]
    else
      authorize [:admin, @push_notification]
    end
  end

  def apply_policy_scope
    custom_scope = PushNotification.where(PushNotification.user_based_scope(current_user, params))
    PushNotification.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
