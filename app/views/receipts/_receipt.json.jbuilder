if params[:ds]
  hash = {id: receipt.receipt_id, name: receipt.receipt_id}
  json.extract! hash, :id, :name
else
  json.extract! receipt, :id, :receipt_id
  if current_user.buyer?
    json.url buyer_receipt_path(receipt, format: :json)
  else
    json.url admin_receipt_path(receipt, format: :json)
  end
end
