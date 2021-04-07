class Admin::PushNotificationPolicy < PushNotificationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def index?
    user.role?('admin')
  end

  def new?
    true
  end

  def create?
    true
  end

  def permitted_attributes
    [:title, :content, :role, :url]
  end
end
