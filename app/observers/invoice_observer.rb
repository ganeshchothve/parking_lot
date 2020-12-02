class InvoiceObserver < Mongoid::Observer
  def before_validation invoice
    invoice.net_amount = invoice.amount if invoice.net_amount.blank?
  end
end
