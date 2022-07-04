class CouponUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'discount'

  def perform current_user_id
    Coupon.each do |coupon|
      if coupon.receipt.present? && coupon.receipt.token_eligible?
        coupon.set(
          value: coupon.discount.payment_adjustments.nin(absolute_value: [nil, '']).collect{ |payment_adjustment| payment_adjustment.absolute_value }.sum.try(:round, 2),
          variable_discount: coupon.discount.payment_adjustments.nin(formula: [nil, '']).collect{ |payment_adjustment| payment_adjustment.calculate(coupon.receipt) }.sum.try(:round, 2)
        )
        TokenDetailsUpdateNotification.perform_async coupon.receipt.user_id, coupon.receipt_id
      end
    end
    receipt_ids = Coupon.pluck(:receipt_id)
    Discount.each do |discount|
      Receipt.where(project_id: discount.project_id, token_type_id: discount.token_type_id, token_number: {"$gte": discount.start_token_number, "$lte": discount.end_token_number}, id: {"$nin": receipt_ids}).each do |receipt|
        TokenDetailsUpdateNotification.perform_async receipt.user_id, receipt.id if receipt.token_eligible? && receipt.generate_coupon
      end
    end
    TokenDetailsUpdateCompletedNotification.perform_async current_user_id
  end
end
