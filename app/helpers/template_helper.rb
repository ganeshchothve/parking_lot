module TemplateHelper
  def available_templates(subject_class, subject_class_resource)
    project_id = subject_class_resource.try(:project_id)
    custom_templates = ::Template::CustomTemplate.where(subject_class: subject_class, booking_portal_client_id: subject_class_resource.booking_portal_client_id, is_active: true).in(project_ids: [project_id, []]).pluck(:name, :id)
    custom_templates
  end
end