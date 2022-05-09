class Admin::Template::NotificationTemplatePolicy < TemplatePolicy
  def permitted_attributes params={}
    attributes = super
    if user.role?('superadmin')
      attributes += [:data]
    end
    attributes
  end
end
