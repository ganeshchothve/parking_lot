module ReceiptHelper
  def available_statuses receipt
    if receipt.new_record?
      [ 'pending' ]
    else
      statuses = receipt.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end
end