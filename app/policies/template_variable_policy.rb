class TemplateVariablePolicy < TemplatePolicy
  def permitted_attributes params={}
    [:id, :number, :content, :_destroy]
  end
end
