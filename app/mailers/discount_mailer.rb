class DiscountMailer < ApplicationMailer

  def send_draft discount_id, user_id
    @discount = Discount.find(discount_id)
    @user = User.find(user_id)
    mail(to: @user.email, subject: "Discount #{@discount.name} Requested")
  end

  def send_approved discount_id
    @discount = Discount.find(discount_id)
    mail(to: @discount.created_by.email, cc: @discount.approved_by.email, subject: "Discount #{@discount.name} Approved")
  end

  def send_disabled discount_id
    @discount = Discount.find(discount_id)
    mail(to: @discount.created_by.email, cc: (@discount.approved_by.email rescue []), subject: "Discount #{@discount.name} Disabled")
  end
end
