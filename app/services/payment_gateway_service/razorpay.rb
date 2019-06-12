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
  end
end
