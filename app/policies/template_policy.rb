class TemplatePolicy < ApplicationPolicy
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
    attributes = [:content, :subject, :is_active]
    attributes
  end
end
