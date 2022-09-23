class Template::CustomTemplatePolicy < TemplatePolicy

  def new?
    false
  end

  def create?
    false
  end

end
