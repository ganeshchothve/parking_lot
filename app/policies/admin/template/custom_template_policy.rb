class Admin::Template::CustomTemplatePolicy < Template::CustomTemplatePolicy
  def permitted_attributes params={}
    attributes = super
    if user.role?('superadmin')
      attributes += [:name, :subject_class, :is_active, :content, :project_id]
    end
    attributes
  end
end