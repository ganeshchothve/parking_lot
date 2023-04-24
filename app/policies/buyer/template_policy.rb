class Buyer::TemplatePolicy < TemplatePolicy

  def choose_template_for_print?
    user.role.in?(User::BUYER_ROLES)
  end

  def print_template?
    choose_template_for_print?
  end
  
end