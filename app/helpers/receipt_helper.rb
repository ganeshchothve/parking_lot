module ReceiptHelper
  def available_statuses receipt
    if receipt.new_record?
      [t('receipts.status.pending'), 'pending' ]
    else
      statuses = receipt.aasm.events(permitted: true).collect{|x| x.name.to_s}
      statuses = statuses.collect{|rec| [t("receipts.status.#{rec}"), rec.to_s]}
    end
  end
end