class Admin::TemplatePolicy < TemplatePolicy

  def new?
    Admin::Template::CustomTemplatePolicy.new(user, Template::CustomTemplate.new).new?
  end

  def create?
    new?
  end

  def choose_template_for_print?
    user.role.in?(%w(admin sales sales_admin superadmin))
  end

  def print_template?
    choose_template_for_print?
  end

end
