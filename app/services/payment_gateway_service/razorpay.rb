module PaymentGatewayService
  class Razorpay < Default
    def gateway_url(search_id)
      return "/dashboard/user/searches/#{search_id}/razorpay-payment/#{@receipt.receipt_id}"
    end

    def response_handler! params
      begin
        response = ::Razorpay::Payment.fetch(params[:payment_id]).capture({
          amount: @receipt.total_amount.to_i * 100
        })
        @receipt.tracking_id = params[:payment_id]
        @receipt.payment_identifier = params[:payment_id]
        # @receipt.gateway_response = response
        if response.status == 'captured'
          @receipt.status = "success"
          @receipt.status_message = "success"
        else
          @receipt.status = "failed"
          @receipt.status_message = "Some unknown error"
        end
      rescue => e
        @receipt.status = "failed"
        @receipt.status_message = e.to_s
      end
      @receipt.save
    end
  end
end
