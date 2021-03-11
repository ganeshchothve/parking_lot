module NotificationConcern
  extend ActiveSupport::Concern

  #
  # This index action for Admin, users where they can view all the notifications sent.
  # Admin can  view all the notifications and user can view the Notification sent to them.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @notifications = Notification.build_criteria params
    @notifications = @notifications.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page])
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
    @notification = Notification.find(params[:id])
  end
end
