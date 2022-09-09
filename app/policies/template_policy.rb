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

  def new?
    Admin::Template::CustomTemplatePolicy.new(user, Template::CustomTemplate.new).new?
  end

  def create?
    new?
  end

  def permitted_attributes params={}
    attributes = [:content, :subject, :is_active, :data]
    attributes
  end
end
