module ReceiptHelper
  def available_statuses receipt
    statuses = receipt.aasm.events(permitted: true).collect{|x| x.name.to_s}
    statuses = statuses.collect{|rec| [rec.to_s.titleize, rec.to_s]}
  end
end