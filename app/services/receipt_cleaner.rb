class ReceiptCleaner
  def perform
    Receipt.where(payment_mode: 'online').where(status: 'pending').where(created_at: {"$lte": Time.now.beginning_of_day - 1.day}).destroy_all
  end
end
