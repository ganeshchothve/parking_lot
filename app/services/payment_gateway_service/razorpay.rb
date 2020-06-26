module PaymentGatewayService
  class Razorpay < Default
    def gateway_url(search_id)
      return "/dashboard/user/searches/#{search_id}/gateway-payment/#{@receipt.receipt_id}"
    end

    def response_handler! params
      begin
        response = ::Razorpay::Payment.fetch(params[:payment_id]).capture({amount: @receipt.total_amount.to_i * 100})
        @receipt.payment_identifier = params[:payment_id]
        @receipt.tracking_id = params[:payment_id]
        if response.status == 'captured'
          initiate_transfer_on_razorpay(@receipt, params)
          @receipt.clearance_pending! 
          @receipt.status_message = "success"
        else
          @receipt.failed! if %w[pending clearance_pending].include? @receipt.status
          @receipt.status_message = "Some unknown error"
        end
      rescue => e
        @receipt.failed! if %w[pending clearance_pending].include? @receipt.status
        @receipt.status_message = e.to_s
      end
      @receipt.save
    end

    def initiate_transfer_on_razorpay(receipt, params)
      account = receipt.account
      if account.present? && params[:payment_id].present?
        auth = {:username => account.key, :password => account.secret}
        response = HTTParty.post("https://api.razorpay.com/v1/payments/#{params[:payment_id]}/transfers",:basic_auth => auth, :body => { :transfers => [{:account => account.account_number.to_s, :amount => (receipt.total_amount * 100), :currency => "INR", :on_hold => false}]}.to_json, :headers => { 'Content-Type' => 'application/json' })
        response["items"].each do |item|
          receipt.transfer_details << {id: item.dig("id"), amount: item.dig("amount")}
        end
      end
    end
  end
end
