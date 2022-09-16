class Admin::Template::CustomTemplatePolicy < Template::CustomTemplatePolicy

  def new?
    user.role.in?(%w(superadmin))
  end

  def create?
    new?
  end

  def permitted_attributes params={}
    attributes = super
    if user.role?('superadmin')
      attributes += [:name, :subject_class, :is_active, :content, project_ids: []]
    end
    attributes
  end
end