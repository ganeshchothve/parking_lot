class Buyer::ProjectPolicy < ProjectPolicy
  def switch_project?
    user.buyer? && user.leads.count > 1
  end
end
