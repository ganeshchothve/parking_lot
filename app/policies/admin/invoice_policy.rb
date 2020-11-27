class Admin::InvoicePolicy < InvoicePolicy
  def index?
    user.role.in?(%w(admin superadmin channel_partner))
  end
end
