class Template::CustomTemplatePolicy < TemplatePolicy

  def new?
    user.role.in?(%w(superadmin))
  end

  def create?
    new?
  end

end
