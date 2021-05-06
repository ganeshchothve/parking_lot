class UserNotificationTokenPolicy < ApplicationPolicy
  # def index?  def new?  def edit?  def create?  def update? from ApplicationPolicy

  def update?
    true
  end

  def permitted_attributes(_params = {})
    attributes = [:token, :os, :device]
    attributes
  end
end
