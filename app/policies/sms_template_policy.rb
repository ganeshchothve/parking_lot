class SmsTemplatePolicy < ApplicationPolicy
  def index?
    user.role?('superadmin')
  end

  def edit?
    index?
  end

  def update?
    index?
  end

  def permitted_attributes params={}
    attributes = [:content]
    attributes
  end
end
