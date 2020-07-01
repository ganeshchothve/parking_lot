class RazorpayTransferWorker
  include Sidekiq::Worker

  def perform receipt_id
    receipt = Receipt.where(id: receipt_id).first
    if receipt
      account = receipt.account
      if account.present? && receipt.tracking_id.present?
        auth = {:username => account.key, :password => account.secret}
        response = HTTParty.post("https://api.razorpay.com/v1/payments/#{receipt.tracking_id}/transfers",:basic_auth => auth, :body => { :transfers => [{:account => account.account_number.to_s, :amount => (receipt.total_amount * 100), :currency => "INR", :on_hold => false}]}.to_json, :headers => { 'Content-Type' => 'application/json' })
        if response.code == 200
          response["items"].each do |item|
            receipt.transfer_details << {id: item.dig("id"), amount: item.dig("amount")}
          end
        else
          Rails.logger.error "Error - #{response.message}"
          receipt.status_message = "Transfer not initiated"
        end
      else
        receipt.status_message = "Transfer not initiated"
      end
      receipt.save
    end
  end
end
