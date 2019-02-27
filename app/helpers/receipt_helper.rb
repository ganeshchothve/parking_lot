module ReceiptHelper
  def available_statuses receipt
    statuses = receipt.aasm.events(permitted: true).collect{|x| x.name.to_s}
    if receipt.new_record?
      if statuses.include?('clearance_pending')
        statuses.reject!{|x| x == "pending"}
      else
        statuses.reject!{|x| x == "success"}  
      end
    end
    statuses = statuses.collect{|rec| [rec.to_s.titleize, rec.to_s]}
  end
end