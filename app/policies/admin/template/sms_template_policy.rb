class Admin::Template::SmsTemplatePolicy < Template::SmsTemplatePolicy

  def permitted_attributes params={}
    attributes = super
    if user.role?('superadmin')
      attributes += [:dlt_tag_id, :dlt_temp_id, :template_variables]
      attributes += [template_variables_attributes: TemplateVariablePolicy.new(user, TemplateVariable.new).permitted_attributes]
    end
    attributes
  end
end
