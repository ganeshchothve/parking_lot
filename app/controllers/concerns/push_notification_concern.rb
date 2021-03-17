module PushNotificationConcern
  extend ActiveSupport::Concern

  #
  # This index action for Admin, users where they can view all the notifications sent.
  # Admin can  view all the notifications and user can view the Notification sent to them.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @push_notifications = PushNotification.build_criteria params
    @push_notifications = @push_notifications.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  #
  # This show action for Admin, users where they can view the details of a particular Notification.
  #
  # @return [{}] record with array of Hashes.
  #
  def show
    render template: 'buyer/notifications/show'
  end

  private

  def set_notification
    if %w(new create).include?(params[:action])
      @push_notification = PushNotification.new(booking_portal_client_id: current_client.id)
    else
      @push_notification = PushNotification.find(params[:id])
    end
  end
end
