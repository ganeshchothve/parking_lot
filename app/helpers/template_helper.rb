module TemplateHelper
  def available_templates(subject_class, subject_class_resource, project_id)
    custom_templates = ::Template::CustomTemplate.where(subject_class: subject_class, project_ids: project_id, booking_portal_client_id: subject_class_resource.booking_portal_client_id, is_active: true).pluck(:name, :id)
    custom_templates
  end
end