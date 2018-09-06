module PaymentGatewayService
  class CCAvenue < Default
    def build_parameters(search_id)
      payload = ""
      payload += "merchant_id=#{payment_profile[:merchant_id]}&"
      payload += "amount=" + @receipt.total_amount.to_s + "&"
      payload += "order_id=" + @receipt.order_id.to_s + "&"
      payload += "currency=INR&"
      payload += "language=EN&"
      payload += "redirect_url=#{redirect_url(search_id)}&"
      payload += "cancel_url=#{cancel_url(search_id)}&"
      crypto = PaymentGatewayService::CCAvenueCrypto.new
      encrypted_data = crypto.encrypt(payload, payment_profile[:working_key])
      return encrypted_data
    end

    def gateway_url(search_id)
      return "/dashboard/user/searches/#{search_id}/gateway-payment/#{@receipt.receipt_id}"
    end

    def response_handler! params
      if Rails.env.development?
        @receipt.status = params[:status]
        @receipt.tracking_id = SecureRandom.hex
        @receipt.payment_identifier = SecureRandom.hex
        @receipt.status_message = ""
      else
        encResponse = params[:encResp]
        crypto = PaymentGatewayService::CCAvenueCrypto.new
        decResp = crypto.decrypt(encResponse, payment_profile[:working_key])
        decResp = decResp.split("&") rescue []
        decResp.each do |key|
          if key.from(0).to(key.index("=")-1) == 'order_status'
            status = key.from(key.index("=")+1).to(-1).downcase
            if(status.downcase == "success")
              @receipt.status = "success"
              @receipt.status_message = "success"
            else
              @receipt.status = "failed"
            end
          end
          if key.from(0).to(key.index("=")-1) == 'tracking_id'
            @receipt.tracking_id = key.from(key.index("=")+1).to(-1)
          end
          if key.from(0).to(key.index("=")-1) == 'bank_ref_no'
            @receipt.payment_identifier = key.from(key.index("=")+1).to(-1)
          end
          if key.from(0).to(key.index("=")-1) == 'failure_message'
            @receipt.status_message = key.from(key.index("=")+1).to(-1).downcase
          end
          if key.from(0).to(key.index("=")-1) == 'order_id'
            @receipt.id.to_s == key.from(key.index("=")+1).to(-1)
          else
            # TODO: Raise an error email to us. Tampered data
          end
        end
      end
      @receipt.save
    end

    def payment_profile
      merchant_id = (Rails.env.development? ? "189462" : ENV_CONFIG['ccavenue']['merchant_id'])
      working_key = (Rails.env.development? ? "B666339315E4F58445C11591EB7993DE" : ENV_CONFIG['ccavenue']['working_key'])
      access_code = (Rails.env.development? ? "AVVT80FI20AH22TVHA" : ENV_CONFIG['ccavenue']['access_code'])
      return {
        merchant_id: merchant_id,
        working_key: working_key,
        access_code: access_code
      }.with_indifferent_access
    end

    def redirect_url(search_id)
      "#{protocol}#{Rails.application.config.action_mailer.default_url_options[:host]}/payment/#{@receipt.receipt_id}/process_payment/success"
    end

    def cancel_url(search_id)
      "#{protocol}#{Rails.application.config.action_mailer.default_url_options[:host]}/payment/#{@receipt.receipt_id}/process_payment/failure"
    end

    def ccavenue_url
      if Rails.env.production?
        return "https://ccavenue.com/transaction/transaction.do?command=initiateTransaction"
      elsif Rails.env.development?
        return "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction"
      else
        return "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction"
      end
    end

    def protocol
      (Rails.application.config.action_mailer.default_url_options[:port].to_i == 443) ? "https://" : "http://"
    end
  end

  class CCAvenueCrypto
    INIT_VECTOR = (0..15).to_a.pack("C*")

    def encrypt(plain_text, key)
      secret_key =  [Digest::MD5.hexdigest(key)].pack("H*")
      cipher = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
      cipher.encrypt
      cipher.key = secret_key
      cipher.iv  = INIT_VECTOR
      encrypted_text = cipher.update(plain_text) + cipher.final
      return (encrypted_text.unpack("H*")).first
    end

    def decrypt(cipher_text,key)
      secret_key =  [Digest::MD5.hexdigest(key)].pack("H*")
      encrypted_text = [cipher_text].pack("H*")
      decipher = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
      decipher.decrypt
      decipher.key = secret_key
      decipher.iv  = INIT_VECTOR
      decrypted_text = (decipher.update(encrypted_text) + decipher.final).gsub(/\0+$/, '')
      return decrypted_text
    end
  end
end
