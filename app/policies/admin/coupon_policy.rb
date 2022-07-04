class Admin::CouponPolicy < CouponPolicy

  def show?
    super && user.role.in?(%w(sales sales_head superadmin admin crm))
  end

end
