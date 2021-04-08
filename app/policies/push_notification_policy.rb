class PushNotificationPolicy < ApplicationPolicy
  # def edit? def update? def new? def create? def permitted_attributes from ApplicationPolicy

  def index?
    false
  end

  def new?
    false
  end

  def create?
    false
  end
end
